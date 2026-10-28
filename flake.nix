{
  description = "Deterministically randomize your binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.funky ];
        };
    in
    {
      overlays.funky = import ./overlay.nix;

      checks = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
          shuffleSeed = 4;

          # PHP with its bundled extensions shuffled too (see README).
          php =
            let
              callPackage = pkgs.newScope {
                stdenv = pkgs.funkyenv.seed shuffleSeed;
                inherit callPackage;
              };
            in
            (callPackage (pkgs.path + "/pkgs/development/interpreters/php") { }).php85;

          openssh = pkgs.openssh.override { stdenv = pkgs.funkyenv.seed shuffleSeed; };

          # brotli 1.2.1 fixes CVE-2026-111497 in the decoder; nixpkgs still has 1.2.0.
          brotli = (pkgs.brotli.override { stdenv = pkgs.funkyenv.seed shuffleSeed; }).overrideAttrs (prev: {
            version = "1.2.1";
            src = prev.src.override {
              tag = "v1.2.1";
              hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
            };
          });

          # nginx with the brotli module, both built with funkyenv against that brotli.
          nginx = pkgs.nginx.override {
            stdenv = pkgs.funkyenv.seed shuffleSeed;
            modules = pkgs.nginx.modules ++ [ (pkgs.nginxModules.brotli.override { inherit brotli; }) ];
          };
        in
        {
          default = pkgs.php.override { stdenv = pkgs.funkyenv.seed shuffleSeed; };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          wordpress = pkgs.testers.runNixOSTest (import ./tests/wordpress.nix { inherit php; });
          ssh = pkgs.testers.runNixOSTest (import ./tests/ssh.nix { inherit openssh; });
          nginx = pkgs.testers.runNixOSTest (import ./tests/nginx.nix { inherit nginx brotli; });
        }
      );

      formatter = forEachSystem (system: (pkgsFor system).nixfmt-tree);
    };
}
