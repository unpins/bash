{
  description = "Standalone build of bash";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Native-only by design. Windows is architecturally infeasible:
  # bash on Windows requires Cygwin/MSYS POSIX emulation (fork(),
  # signals, FDs), which is a process-tree singleton DLL. Static
  # linking that runtime is unsupported by upstream and would break
  # fork() between processes anyway. Use busybox-w32 for a Windows
  # shell. See feedback_unpins_bash_windows_blocked.md in memory.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "bash";
    };
}
