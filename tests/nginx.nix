# nginx serving brotli-compressed responses over HTTP/2, with nginx, its brotli
# module and libbrotli all built with funkyenv.
{ nginx, brotli }:

{
  name = "funkyenv-nginx";

  nodes.machine =
    { pkgs, ... }:
    {
      services.nginx = {
        enable = true;
        package = nginx;
        # Not recommendedBrotliSettings: it adds nixpkgs' (unfunky) brotli module.
        appendHttpConfig = ''
          brotli on;
          brotli_types text/plain;
          # From nixpkgs' default moreheaders module, which must still be there.
          more_set_headers "X-Funky: yes";
        '';
        virtualHosts.localhost = {
          extraConfig = "http2 on;";
          root = pkgs.writeTextDir "index.html" (pkgs.lib.strings.replicate 200 "funky ");
        };
      };
      environment.systemPackages = [
        brotli
        pkgs.curl
      ];
    };

  testScript = ''
    machine.wait_for_unit("nginx")
    machine.wait_for_open_port(80)

    with subtest("nginx serves brotli over HTTP/2"):
        headers = machine.succeed(
            "curl -fsS --http2-prior-knowledge -H 'Accept-Encoding: br' -D - -o /tmp/index.br http://localhost/"
        ).lower()
        assert "http/2 200" in headers, headers
        assert "content-encoding: br" in headers, headers
        assert "x-funky: yes" in headers, headers

    with subtest("the funky brotli CLI decompresses it"):
        machine.succeed("brotli --version | grep -F 'brotli 1.2.1'")
        assert machine.succeed("brotli -d -c /tmp/index.br") == "funky " * 200

    master = machine.succeed("systemctl show -P MainPID nginx").strip()
    worker = machine.succeed("pgrep -f 'nginx: worker' | head -1").strip()

    with subtest("nginx runs the funkyenv build"):
        for pid in [master, worker]:
            exe = machine.succeed(f"readlink -f /proc/{pid}/exe").strip()
            assert exe.startswith("${nginx}/"), exe

    with subtest("the worker loaded the funky brotli module and libbrotli"):
        maps = machine.succeed(f"cat /proc/{worker}/maps")
        module = "${nginx}/modules/ngx_http_brotli_filter_module.so"
        assert module in maps, maps
        libs = {line.split()[-1] for line in maps.splitlines() if "libbrotli" in line}
        assert libs, maps
        for lib in libs:
            assert lib.startswith("${brotli.lib}/"), lib

    with subtest("they contain funkyenv's canary functions"):
        for binary in [f"/proc/{worker}/exe", module, *sorted(libs)]:
            canaries = machine.succeed(
                f"grep -a -o '__funkyenv_canary_[0-9]*' {binary} | sort -u | wc -l"
            ).strip()
            assert canaries == "32", f"{binary}: {canaries} canaries"
  '';
}
