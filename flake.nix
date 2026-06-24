{
  description = "bash as a single self-contained binary";

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

      # Linux bitcode multicall: bash joins the native unpinbox mega (a shell
      # in it). `sh` is the only alias. Link inputs are inferred from the
      # build. bash's `main` is 3-arg — main(argc, argv, env) — reading the
      # environment from the THIRD parameter; the mega dispatcher calls every
      # applet as fn(argc, argv, environ) precisely so this works.
      engine = "unpin-llvm";
      multicall = {
        inferLinkInputs = true;
        # Fold into the darwin (Mach-O) mega via the engine, same as grep/bc.
        # (Windows/APE goes through Cosmopolitan — see multicallCosmo below.)
        darwin = true;
        programs = [{ name = "bash"; aliases = [ "sh" ]; }];
      };
      # The Linux build-correctness fix (pin CC to the engine wrapper + force
      # CC_FOR_BUILD=gnu17 for bash's mkbuiltins/mksignames build-tool codegen,
      # which gcc-15/clang otherwise compile under C23 and reject bash-5.3's
      # `typedef unsigned char bool`) now lives in nix-lib's
      # native-overlay/bash.nix — the SINGLE source of truth. The engine's
      # all-deps path applies the very same fix when another package drags bash
      # in as a dependency (e.g. gnugrep propagates bash as its egrep/fgrep
      # runtime shell), so the workaround can't drift between here and there.
      # darwin/windows keep plain pkgsStatic (the cosmo Windows path is
      # windowsBuild above); the fix is a no-op off Linux.
      build = pkgs: unpins-lib.lib.nativeFixes.bash pkgs.pkgsStatic;

      # Cosmo (APE/Windows) multicall MODULE for the `unpinbox` mega-binary,
      # emitted from the cosmo cross build (windowsBuild above, reused
      # untouched); the catalog reads it from
      # `bash.packages.<sys>.windows-x86_64.cosmoMulticallModule`. Cosmo has no
      # link sidecar, so its inputs stay hand-listed (unlike the Linux block).
      # Top-level objects + bash's bundled libs; readline/history/ncurses come
      # from the cosmo cross as depArchives. `sh` is the only alias
      # (bashbug/sh symlinks are dropped in cosmo.nix).
      multicallCosmo = {
        program = "bash";
        programObjs = [
          "alias.o" "array.o" "arrayfunc.o" "assoc.o" "bashhist.o" "bashline.o"
          "bracecomp.o" "braces.o" "copy_cmd.o" "dispose_cmd.o" "error.o" "eval.o"
          "execute_cmd.o" "expr.o" "findcmd.o" "flags.o" "general.o" "hashcmd.o"
          "hashlib.o" "input.o" "jobs.o" "list.o" "locale.o" "mailcheck.o"
          "make_cmd.o" "pathexp.o" "pcomplete.o" "pcomplib.o" "print_cmd.o"
          "redir.o" "shell.o" "sig.o" "signames.o" "stringlib.o" "subst.o"
          "syntax.o" "test.o" "trap.o" "unwind_prot.o" "variables.o" "version.o"
          "xmalloc.o" "y.tab.o"
        ];
        gnulibArchives = [
          "builtins/libbuiltins.a" "lib/sh/libsh.a" "lib/glob/libglob.a"
          "lib/tilde/libtilde.a" "lib/intl/libintl.a"
        ];
        aliases = [ "sh" ];
        depArchives = pkgs: [
          "${pkgs.pkgsCross.cosmo.readline}/lib/libreadline.a"
          "${pkgs.pkgsCross.cosmo.readline}/lib/libhistory.a"
          "${pkgs.pkgsCross.cosmo.ncurses}/lib/libncurses.a"
        ];
      };
    };
}
