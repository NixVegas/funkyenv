# sshd and the ssh client both running an OpenSSH built with funkyenv.
{ openssh }:

{
  name = "funkyenv-ssh";

  nodes.machine = {
    services.openssh.enable = true;
    # The server and the client are configured separately.
    services.openssh.package = openssh;
    programs.ssh.package = openssh;
  };

  testScript = ''
    machine.wait_for_unit("sshd")
    machine.wait_for_open_port(22)

    with subtest("sshd runs the funkyenv openssh"):
        pid = machine.succeed("systemctl show -P MainPID sshd").strip()
        exe = machine.succeed(f"readlink -f /proc/{pid}/exe").strip()
        assert exe.startswith("${openssh}/"), exe

    with subtest("ssh on PATH is the funkyenv openssh"):
        ssh = machine.succeed("readlink -f $(command -v ssh)").strip()
        assert ssh.startswith("${openssh}/"), ssh

    with subtest("the running sshd and ssh contain funkyenv's canary functions"):
        for binary in [f"/proc/{pid}/exe", ssh]:
            canaries = machine.succeed(
                f"grep -a -o '__funkyenv_canary_[0-9]*' {binary} | sort -u | wc -l"
            ).strip()
            assert canaries == "32", f"{binary}: {canaries} canaries"

    with subtest("logging in over ssh works"):
        machine.succeed("ssh-keygen -q -t ed25519 -N ''' -f /root/.ssh/id_ed25519")
        machine.succeed("cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys")
        assert machine.succeed(
            "ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@localhost echo funky"
        ).strip() == "funky"
  '';
}
