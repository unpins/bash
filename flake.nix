{
  description = "Standalone build of bash";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unpins-lib.url = "github:unpins/nix-lib/v1";
  };

  # Native-only by design. Windows is architecturally infeasible:
  # bash on Windows requires Cygwin/MSYS POSIX emulation (fork(),
  # signals, FDs), which is a process-tree singleton DLL. Static
  # linking that runtime is unsupported by upstream and would break
  # fork() between processes anyway. Use busybox-w32 for a Windows
  # shell. See feedback_unpins_bash_windows_blocked.md in memory.
  outputs = { self, nixpkgs, unpins-lib }:
    let
      ulib = unpins-lib.lib;
      nixpkgsFor = ulib.forAllNative (system: import nixpkgs { inherit system; });
    in
    {
      packages = ulib.forAllNative (system:
        let
          pkgs = nixpkgsFor.${system};
          # pkgsStatic on Linux yields a fully static musl binary.
          # On Darwin, libSystem stays dynamic (Apple constraint), but
          # everything else is linked statically — portable across any
          # macOS without a /nix/store.
          bashStatic = pkgs.pkgsStatic.bash.overrideAttrs (_: {
            stripAllList = [ "bin" ];
          });
        in
        {
          # bash splits outputs into "out" (bin/bash + share/bash-completion +
          # etc/) and "man". symlinkJoin merges both so the action-build tarball
          # picks up share/man/ alongside the binary.
          default = pkgs.symlinkJoin {
            name = "bash-${bashStatic.version}";
            paths = [ bashStatic.out bashStatic.man ];
            passthru = { inherit (bashStatic) version pname; };
          };
        });

      apps = ulib.forAllNative (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/bash";
        };
      });
    };
}
