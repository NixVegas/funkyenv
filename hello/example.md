# how funkyenv looks in radare2

## build some stuff

```console
$ nix repl
Nix 2.34.9
Type :? for help.
nix-repl> :lf .
Added 15 variables.
_type, checks, formatter, inputs, lastModified, lastModifiedDate, narHash, outPath, outputs, overlays, rev, revCount, shortRev, sourceInfo, submodules

nix-repl> pkgs = import inputs.nixpkgs { overlays = [ overlays.funky ]; system = "x86_64-linux"; }

nix-repl> :b pkgs.hello

This derivation produced the following outputs:
  out -> /nix/store/pa6rydwgjxxmmvdxap7qk9c85h8jbimy-hello-2.12.3

nix-repl> :b pkgs.hello.override { stdenv = pkgs.funkyenv.seed 42; }

This derivation produced the following outputs:
  out -> /nix/store/bayhs1p1w7ffchm8276m3all63zxchnv-hello-2.12.3

nix-repl> :b pkgs.hello.override { stdenv = pkgs.funkyenv.seed 43; }

This derivation produced the following outputs:
  out -> /nix/store/mcf2sd75bznripifflv0q6gb1jb9dpbi-hello-2.12.3
```

## load the normal version in radare2

[normal.md](normal.md)

## load the funky version

[funky-42.md](funky-42.md)

## and compare with the other funky version

[funky-43.md](funky-43.md)
