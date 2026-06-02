# bash via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# nixpkgs 26.05's bash (5.3p9) + our cosmo ncurses/readline overlays
# build clean against cosmocc 4.0.2 without *source* patches —
# superconfigure's bash/readline/ncurses diffs that the playground
# version (cosmo-windows.nix using cosmoStdenv) carried turned out to
# be unnecessary at this cosmocc version.
#
# One build-env flag is needed since the 26.05 bump, though: the build
# host gcc is now gcc-15, which defaults to `-std=gnu23` where `bool`
# is a reserved keyword. bash cross-compiles its build-time codegen
# tools (mkbuiltins, …) with that host gcc, and `bashansi.h`'s fallback
# `typedef unsigned char bool;` (reached because the *cosmo* configure
# probe reports no native C bool) then fails to compile. Pinning the
# build-tool standard to gnu17 — via `CFLAGS_FOR_BUILD`, which flows into
# `CCFLAGS_FOR_BUILD` while the separate `@CROSS_COMPILE@`
# (`-DCROSS_COMPILING`) stays intact — makes `bool` a plain identifier
# again so the typedef is legal. Host/native musl builds are unaffected:
# there build == host, so the same gcc-15 that compiles the tools also
# ran configure and reported native bool, skipping the typedef entirely.
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
  # See header: gcc-15 (26.05) defaults to gnu23 where `bool` is a keyword;
  # pin the cross build-tool standard to gnu17 so bashansi.h's bool typedef
  # compiles. Reaches @CFLAGS_FOR_BUILD@ → CCFLAGS_FOR_BUILD; -DCROSS_COMPILING
  # (@CROSS_COMPILE@) is appended separately and untouched.
  CFLAGS_FOR_BUILD = (oa.CFLAGS_FOR_BUILD or "") + " -std=gnu17";
  postFixup = (oa.postFixup or "") + ''
    rm -f $out/bin/sh.exe $out/bin/bashbug
  '';
})
