{
  description = "Standalone build of bash";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: pkgsStatic.bash via mkStandaloneFlake.
  # Windows: routed through Cosmopolitan (`windowsCosmo = true`) because
  # mingw lacks fork()/signals that bash's job control needs (see
  # docs/platforms/mingw.md). Cosmocc implements fork() on Windows via
  # CreateProcessW + page copy. Per-target cosmo fix in
  # `unpins/nix-lib/cosmo/bash.nix` (apelink ELF→PE, drop `bashbug`/`sh`).
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "bash";
      windowsCosmo = true;
    };
}
