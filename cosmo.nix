# bash via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# nixpkgs 25.11's bash (5.3p3) + our cosmo ncurses/readline overlays
# build clean against cosmocc 4.0.2 without source patches —
# superconfigure's bash/readline/ncurses diffs that the playground
# version (cosmo-windows.nix using cosmoStdenv) carried turned out to
# be unnecessary at this cosmocc version.
#
# The cosmo cross stdenv auto-apelinks every ELF in $out/bin (ELF →
# PE32+, rename to `<name>.exe`) in preFixupHooks. Cleanup we still
# do ourselves in postFixup (after the rename):
#   - `sh.exe` — auto-hook's Phase 2 rewired the upstream `sh ->
#     bash` symlink into `sh.exe -> bash.exe`. Drop it: bash ships
#     single-name; `withAliases` embeds the `sh` alias in UNPIN_META
#     at the release layer.
#   - `bashbug` — shell script whose shebang `#!$out/bin/bash`
#     points at a file the rename made non-existent. Drop it.
#     (Has to be in postFixup, not postInstall: nixpkgs's automatic
#     shebang rewrite for bashbug runs in fixupPhase and would
#     error on a missing file.)
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
in
cosmoPkgs.bash.overrideAttrs (oa: {
  postFixup = (oa.postFixup or "") + ''
    rm -f $out/bin/sh.exe $out/bin/bashbug
  '';
})
