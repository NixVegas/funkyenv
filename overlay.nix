final: prev: {
  funkyenv = prev.callPackage ./funkyenv.nix { };
  lldFunkyenv = prev.callPackage ./funkyenv.nix { linker = "lld"; };
}
