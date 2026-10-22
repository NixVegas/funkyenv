# WordPress served by php-fpm running a PHP whose interpreter and bundled
# extensions are all built with funkyenv.
{ php }:

{
  name = "funkyenv-wordpress";

  nodes.machine = {
    services.phpfpm.phpPackage = php;
    services.wordpress.webserver = "nginx";
    services.wordpress.sites."localhost" = { };
  };

  testScript = ''
    machine.wait_for_unit("nginx")
    machine.wait_for_unit("phpfpm-wordpress-localhost")

    with subtest("wordpress returns the install page"):
        assert "Welcome to the famous" in machine.succeed("curl -fsSL localhost")

    with subtest("php-fpm runs the funkyenv php"):
        pid = machine.succeed("systemctl show -P MainPID phpfpm-wordpress-localhost").strip()
        exe = machine.succeed(f"readlink -f /proc/{pid}/exe").strip()
        assert exe.startswith("${php.unwrapped}/"), exe

    with subtest("php and its extensions are linked by mold"):
        for path in machine.succeed(
            "find ${php.unwrapped}/bin/php-fpm $(grep -o '/nix/store/[^ ]*\\.so' ${php}/lib/php.ini)"
        ).split():
            assert "mold " in machine.succeed(f"grep -a -o -m1 'mold [0-9.]*' {path} || true"), path
  '';
}
