# bash via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# nixpkgs' bash (5.3p9) + our cosmo ncurses/readline overlays build
# against cosmocc without source patches beyond the .exe lookup below.
#
# One build-env flag is needed since the 26.05 bump: the build
# host gcc is now gcc-15, which defaults to `-std=gnu23` where `bool`
# is a reserved keyword. bash cross-compiles its build-time codegen
# tools (mkbuiltins, …) with that host gcc, and `bashansi.h`'s fallback
# `typedef unsigned char bool;` (reached because the *cosmo* configure
# probe reports no native C bool) then fails to compile. Pinning the
# build-tool standard to gnu17 — via `CFLAGS_FOR_BUILD`, which flows into
# `CCFLAGS_FOR_BUILD` while the separate `@CROSS_COMPILE@`
# (`-DCROSS_COMPILING`) stays intact — makes `bool` a plain identifier
# again so the typedef is legal.
#
# The cosmo cross stdenv auto-apelinks every ELF in $out/bin (ELF →
# PE32+, rename to `<name>.exe`) in preFixupHooks. Cleanup we still
# do ourselves in postFixup (after the rename):
#   - `sh.exe` — auto-hook's Phase 2 rewired the upstream `sh ->
#     bash` symlink into `sh.exe -> bash.exe`. Drop it: the `sh` alias
#     is declared in the flake's `multicallCosmo.aliases` and nix-lib embeds it
#     in the binary; no `sh.exe` ships.
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

  # Windows command lookup: catalog programs install as `<name>.exe` hardlinks
  # (cmd.exe/PowerShell find them via PATHEXT), but Cosmopolitan does not append
  # an executable suffix during path resolution, so a bare `ls` typed at the
  # bash prompt never resolves. The patch teaches bash's find_in_path_element to
  # retry a PATH candidate with `.exe` when the bare name is missing — mirroring
  # native Windows shells and keeping a single on-disk name (no `ls` + `ls.exe`
  # pair). `__COSMOCC__`-guarded, so it is inert on the Linux/macOS static
  # builds. Applied via postPatch with explicit -p1 to stay independent of how
  # nixpkgs applies the upstream bash5x-NNN patches. See docs/platforms/cosmocc.md.
  postPatch = (oa.postPatch or "") + ''
    patch -p1 < ${./findcmd-exe-lookup.patch}
  '';
  postFixup = (oa.postFixup or "") + ''
    rm -f $out/bin/sh.exe $out/bin/bashbug
    for _mo in $outputs; do
      rm -f "''${!_mo}"/share/man/man1/bashbug.1*
    done
  '';
})
