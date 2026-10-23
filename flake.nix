{
  description = "Developer SDK for nixpkgs gold(tm)";

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
        in
        {
          default = pkgs.php.override { stdenv = pkgs.funkyenv.seed shuffleSeed; };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          wordpress = pkgs.testers.runNixOSTest (import ./tests/wordpress.nix { inherit php; });
          ssh = pkgs.testers.runNixOSTest (import ./tests/ssh.nix { inherit openssh; });
        }
      );

      formatter = forEachSystem (system: (pkgsFor system).nixfmt-tree);
    };
}
