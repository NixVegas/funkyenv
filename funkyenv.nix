{
  lib,
  stdenv,
  stdenvAdapters,
  buildPackages,
  makeSetupHook,
  writeText,
  # "mold" or "lld"
  linker ? "mold",
  ...
}:

let
  linkers = {
    mold = {
      stdenv = stdenvAdapters.useMoldLinker stdenv;
      shuffleFlag = seed: "--shuffle-sections=${toString seed}";
      # mold parses the seed as an unsigned 64-bit integer (negative values
      # wrap around), so accept non-negative Nix integers: 0 to 2^63 - 1.
      validSeed = seed: seed >= 0;
      seedRange = "0 to 2^63 - 1";
    };

    lld = {
      # Replace the bintools' ld with (wrapped) lld. Unlike -fuse-ld, this
      # survives builds that clear NIX_CFLAGS_LINK, such as glibc.
      stdenv = stdenv.override (prev: {
        allowedRequisites = null;
        cc = prev.cc.override {
          bintools = prev.cc.bintools.override {
            extraBuildCommands = ''
              ln -sf ${buildPackages.llvmPackages.bintools}/bin/ld.lld "$out/bin/ld"
              ln -sf ${buildPackages.llvmPackages.bintools}/bin/ld.lld "$out/bin/ld.lld"
            '';
          };
        };
      });
      # Only shuffle functions. The flag goes in a response file because the
      # linker wrapper would glob-expand (and, with nullglob, drop) `.text*`.
      shuffleFlag =
        seed:
        "@${writeText "funkyenv-lld-${toString seed}.rsp" "--shuffle-sections=.text*=${toString seed}"}";
      # lld truncates the seed to 32 bits, uses a random seed for 0 (not
      # reproducible) and only reverses the order for 2^32 - 1.
      validSeed = seed: seed >= 1 && seed <= 4294967294;
      seedRange = "1 to 2^32 - 2";
    };
  };

  cfg = linkers.${linker} or (throw "funkyenv: unknown linker '${linker}', expected mold or lld");
  linkerStdenv = cfg.stdenv;

  # Object linked into every binary so the build can check the shuffle worked.
  canary = stdenv.mkDerivation {
    name = "funkyenv-canary";
    src = ./canary.c;
    dontUnpack = true;
    buildPhase = ''
      $CC -c -O2 -fPIC -ffunction-sections "$src" -o canary.o
    '';
    installPhase = ''
      install -Dm644 canary.o "$out/lib/funkyenv-canary.o"
    '';
  };

  verifyShuffleHook = makeSetupHook { name = "funkyenv-verify-shuffle-hook"; } ./verify-shuffle.sh;

  # Function order of each executable and shared library in the normal and the
  # funky package, as normal/<output>/<path>.txt and funky/<output>/<path>.txt.
  functionOrder =
    normal: funky:
    stdenv.mkDerivation {
      name = "${funky.name}-function-order";
      buildCommand = ''
        source ${./function-order.sh}
      ''
      + lib.concatMapStrings (output: ''
        ${lib.optionalString (
          normal ? ${output}
        ) ''dumpFunctionOrder ${normal.${output}} "$out/normal/${output}"''}
        dumpFunctionOrder ${funky.${output}} "$out/funky/${output}"
      '') funky.outputs;
    };
in

{
  seed =
    seed:
    assert lib.assertMsg (builtins.isInt seed && cfg.validSeed seed)
      "funkyenv.seed: ${linker} seed must be an integer from ${cfg.seedRange}, got ${
        lib.generators.toPretty { } seed
      }";
    linkerStdenv.override (stdenvPrev: {
      name = "funkyenv";
      extraAttrs = {
        mkDerivation =
          mkDrvArgs:
          let
            drv = linkerStdenv.mkDerivation mkDrvArgs;
            funkyDrv = drv.overrideAttrs (
              finalAttrs: prevAttrs: {
                # Set the shuffle seed
                __funkyShuffleSeed = seed;

                nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ verifyShuffleHook ];

                passthru = prevAttrs.passthru or { } // {
                  # Compare against the same package built with the normal
                  # stdenv. Overrides applied after the stdenv override are not
                  # included; use functionOrderAgainst for those.
                  functionOrder = functionOrder (stdenv.mkDerivation mkDrvArgs) finalAttrs.finalPackage;
                  # Compare against another package, e.g. pkgs.glibc.
                  functionOrderAgainst = normal: functionOrder normal finalAttrs.finalPackage;
                };

                env = prevAttrs.env or { } // {
                  NIX_CFLAGS_COMPILE = "${prevAttrs.env.NIX_CFLAGS_COMPILE or ""} -ffunction-sections";
                  NIX_LDFLAGS = "${
                    prevAttrs.env.NIX_LDFLAGS or ""
                  } ${cfg.shuffleFlag finalAttrs.__funkyShuffleSeed} ${canary}/lib/funkyenv-canary.o";
                };
              }
            );
          in
          funkyDrv;
      };
    });
}
