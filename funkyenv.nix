{
  lib,
  stdenv,
  stdenvAdapters,
  buildPackages,
  makeSetupHook,
  makeBinaryWrapper,
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
      # makeBinaryWrapper clears NIX_CFLAGS_LINK, where useMoldLinker selects
      # mold, so give its compiler -fuse-ld=mold directly.
      wrapperCC =
        cc:
        cc.override (prev: {
          extraBuildCommands = (prev.extraBuildCommands or "") + ''
            echo " -fuse-ld=mold" >> "$out/nix-support/cc-cflags"
          '';
        });
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
      # lld only shuffles sections it hasn't already ordered, and by default it
      # orders functions by call graph profile (from PGO, e.g. in Firefox), so
      # turn that off.
      shuffleFlag =
        seed:
        "@${writeText "funkyenv-lld-${toString seed}.rsp" "--shuffle-sections=.text*=${toString seed} --call-graph-profile-sort=none"}";
      # lld truncates the seed to 32 bits, uses a random seed for 0 (not
      # reproducible) and only reverses the order for 2^32 - 1.
      validSeed = seed: seed >= 1 && seed <= 4294967294;
      seedRange = "1 to 2^32 - 2";
      # lld is already the compiler's ld.
      wrapperCC = cc: cc;
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

  # Makes makeBinaryWrapper build its wrappers with `cc`, the package's compiler.
  binaryWrapperHook =
    cc:
    makeSetupHook {
      name = "funkyenv-binary-wrapper-hook";
      substitutions.binaryWrapperHook = "${
        makeBinaryWrapper.override { cc = cfg.wrapperCC cc; }
      }/nix-support/setup-hook";
    } ./binary-wrapper.sh;

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
    let
      # Turns a derivation into its funky version. `cc` is the compiler it
      # builds with and `normal` is what functionOrder compares against.
      funkyAttrs = cc: normal: finalAttrs: prevAttrs: {
        # Set the shuffle seed
        __funkyShuffleSeed = seed;

        nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [
          verifyShuffleHook
          (binaryWrapperHook cc)
        ];

        passthru = prevAttrs.passthru or { } // {
          functionOrder = functionOrder normal finalAttrs.finalPackage;
          # Compare against another package, e.g. pkgs.glibc.
          functionOrderAgainst = other: functionOrder other finalAttrs.finalPackage;
        };

        env = prevAttrs.env or { } // {
          NIX_CFLAGS_COMPILE = "${prevAttrs.env.NIX_CFLAGS_COMPILE or ""} -ffunction-sections";
          NIX_LDFLAGS = "${
            prevAttrs.env.NIX_LDFLAGS or ""
          } ${cfg.shuffleFlag finalAttrs.__funkyShuffleSeed} ${canary}/lib/funkyenv-canary.o";
        };
      };
    in
    linkerStdenv.override (stdenvPrev: {
      name = "funkyenv";
      extraAttrs = {
        # functionOrder compares against the same package built with the normal
        # stdenv. Overrides applied after the stdenv override are not included;
        # use functionOrderAgainst for those.
        mkDerivation =
          mkDrvArgs:
          (linkerStdenv.mkDerivation mkDrvArgs).overrideAttrs (
            funkyAttrs linkerStdenv.cc (stdenv.mkDerivation mkDrvArgs)
          );

        # Makes an existing package funky without changing its stdenv, for
        # packages that build their own stdenv but already link with this
        # linker (e.g. Firefox and lld). functionOrder compares against `drv`.
        funkify = drv: drv.overrideAttrs (funkyAttrs drv.stdenv.cc drv);
      };
    });
}
