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
      lib = nixpkgs.lib;
      nixpkgsFor = ulib.forAllNative (system: import nixpkgs { inherit system; });

      # Build bash as a portable single binary for any pkgs view.
      # - On Linux: pkgsStatic.bash → fully static musl.
      # - On Darwin (native or cross): libSystem stays dynamic (Apple
      #   constraint), everything else linked statically.
      buildBash = pkgs:
        let
          bashStatic = pkgs.pkgsStatic.bash.overrideAttrs (_: {
            stripAllList = [ "bin" ];
          });
        in
        pkgs.symlinkJoin {
          name = "bash-${bashStatic.version}";
          paths = [ bashStatic.out bashStatic.man ];
          passthru = { inherit (bashStatic) version pname; };
        };
    in
    {
      packages = ulib.forAllNative (system:
        let pkgs = nixpkgsFor.${system}; in
        {
          default = buildBash pkgs;
        } // lib.optionalAttrs (system == "aarch64-darwin") {
          # Cross-built bash for x86_64-darwin on macos-14 — same pattern
          # as packages.x86_64-linux."windows-x86_64".
          "darwin-x86_64" = buildBash pkgs.pkgsCross.x86_64-darwin;
        });

      apps = ulib.forAllNative (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/bash";
        };
      });
    };
}
