# 🎲 funkyenv

> _Four, four, the [point's marked four](https://emudhra.we-have-a-problem.com/)_
>
> _Ace, Deuce, craps wants four_
>
> _Ace, Deuce, craps wants four_
>
> \- [Jet Set Radio Future, Funky Dealer](https://www.youtube.com/watch?v=CwE2k0HMDfo)

----

funkyenv uses `mold` to deterministically shuffle function order in binaries, in case they are exposed to the internet
and you don't want people [guessing where your functions are](https://en.wikipedia.org/wiki/PHP2Shell).

Add `overlays.funky` to your nixpkgs, then override a package's stdenv with a seed:

```nix
pkgs.hello.override {
  # Make sure you replace "4" with a seed others can't guess
  # try: nix run nixpkgs#ruby -- -rsecurerandom -e 'puts SecureRandom.random_number(1..0x7fffffffffffffff)'
  stdenv = pkgs.funkyenv.seed 4;
}
```

Only code built with that stdenv is shuffled. To shuffle a package and everything
it depends on, replace the stdenv for the whole package set with nixpkgs' `replaceStdenv`:

```nix
pkgs = import nixpkgs {
  overlays = [ funkyenv.overlays.funky ];

  # Make sure you replace "4" with a seed others can't guess
  config.replaceStdenv = { pkgs }: pkgs.funkyenv.seed 4;
};
```

This rebuilds almost everything from source. On Linux, a few core packages
come from nixpkgs' bootstrap and are not shuffled: glibc, gcc's runtime
libraries, binutils, zlib, coreutils, bash, xz, bzip2, gzip, pcre2, acl, attr
and libunistring, among others. glibc can be shuffled separately; see
[glibc](#glibc).

## funkyenv and lldFunkyenv

We provide `pkgs.lldFunkyenv`, which works like `pkgs.funkyenv` and links with lld
instead of mold. It only shuffles function (`.text*`) sections. The seed ranges differ:

| stdenv | seed |
| --- | --- |
| `funkyenv` (mold) | 0 to 2^63 - 1 |
| `lldFunkyenv` (lld) | 1 to 2^32 - 2 (lld treats 0 as random and 2^32 - 1 as "reverse") |

Builds fail unless every executable and shared library they produce was
actually shuffled. funkyenv links 32 small canary functions into each one and
checks after the build that their order changed. Set `dontVerifyFunkyenv = true;`
on a derivation to skip this, e.g. for packages that strip all symbols.

## Comparing function order

Every package built with funkyenv has a `functionOrder` attribute. It builds the
same package with the normal stdenv and lists the functions of each executable
and shared library in address order, so you can diff them:

```nix
helloFunctionOrder = (pkgs.hello.override { stdenv = pkgs.funkyenv.seed 4; }).functionOrder;
```

```sh
diff result/normal/out/bin/hello.txt result/funky/out/bin/hello.txt
```

Files are laid out as `normal/<output>/<path>.txt` and `funky/<output>/<path>.txt`.

The funky lists also contain funkyenv's 32 `__funkyenv_canary_*` functions.

The normal package is rebuilt from the package's original arguments, so
overrides applied after the stdenv override are not included. Use
`functionOrderAgainst` to compare against a package of your choice instead,
e.g. `glibc.functionOrderAgainst pkgs.glibc` for the [glibc](#glibc) example.

## PHP

(This is probably what you came here for)

nixpkgs builds PHP's bundled extensions with the global stdenv, so
`pkgs.php.override { stdenv = ...; }` only shuffles the interpreter. To shuffle
the extensions too, build PHP with a `callPackage` that passes down the stdenv:

```nix
php =
  let
    callPackage = pkgs.newScope {
      # Make sure you replace "4" with a seed others can't guess
      stdenv = pkgs.funkyenv.seed 4;
      inherit callPackage;
    };
  in
  (callPackage (pkgs.path + "/pkgs/development/interpreters/php") { }).php85;
```

For example, to run WordPress on it:

```nix
services.phpfpm.phpPackage = php;
services.wordpress.sites."localhost" = { ... };
```

## glibc

mold can't link glibc's dynamic loader, so use `lldFunkyenv`. glibc also puts
nixpkgs' regular compiler on `PATH` for cross builds; drop it for native builds
so the funky one is used:

```nix
glibc =
  (pkgs.glibc.override {
    # Make sure you replace "4" with a seed others can't guess
    stdenv = pkgs.lldFunkyenv.seed 4;
  }).overrideAttrs
    { depsBuildBuild = [ ]; };
```

Programs only use it if they are built against it or started with its loader,
for example `${glibc}/lib/ld-linux-x86-64.so.2 --library-path ${glibc}/lib ./program`.
Replacing glibc for everything rebuilds all of nixpkgs.

## AI use

The mold funkyenv was lovingly written by hand,
based on [nixpkgs gold](https://github.com/Jaculabilis/nixpkgs-gold).
ld.lld, the verifier, and the tests (e.g. for glibc) were assisted by Claude.
