{
  description = "Standalone build of bash";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: pkgsStatic.bash via mkStandaloneFlake.
  # Windows: routed through Cosmopolitan (`windowsBuild = import ./cosmo.nix …`)
  # because mingw lacks fork()/signals that bash's job control needs (see
  # docs/platforms/mingw.md). Cosmocc implements fork() on Windows via
  # CreateProcessW + page copy. Per-binary cosmo recipe inline in
  # `./cosmo.nix` (apelink ELF→PE, drop `bashbug`/`sh`).
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "bash";
      # No `doCheck`: bash's `make check` is a diff-based harness, not a
      # pass/fail gate — it prints "possible anomaly" diffs but exits 0
      # regardless (verified: a native-static run flagged a `run-alias`
      # mismatch yet still went green), so it can't actually gate a release.
      # It also assumes a full FHS the Nix sandbox lacks (`/bin/echo`, …).
      # The smoke test (`bash --version`) is the floor. See docs/releasing.md
      # "Native test suite".
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };
    };
}
