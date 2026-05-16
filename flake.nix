{
  description = "Standalone build of bash";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unpins-lib.url = "github:unpins/nix-lib";
    unpins-lib.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Linux/macOS: native pkgsStatic via mkStandaloneFlake (works upstream).
  # Windows: not pkgsCross.mingwW64 — bash needs fork()/signals which
  # mingw lacks (see memory: feedback_unpins_bash_windows_blocked.md).
  # Routed through Cosmopolitan instead, using ahgamut/superconfigure's
  # patches (bash 5.2 = 4 lines, readline = pselect tweak, ncurses =
  # one include). See cosmo-windows.nix.
  outputs = { self, nixpkgs, unpins-lib }:
    let
      native = unpins-lib.lib.mkStandaloneFlake {
        inherit self;
        name = "bash";
      };

      windows = import ./cosmo-windows.nix {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        cosmoStdenv = unpins-lib.lib.cosmoStdenv nixpkgs.legacyPackages.x86_64-linux;
      };
    in
    native // {
      packages = native.packages // {
        x86_64-linux = (native.packages.x86_64-linux or { }) // {
          "windows-x86_64" = windows;
        };
      };
    };
}
