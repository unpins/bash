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
        programs = [{ name = "bash"; aliases = [ "sh" ]; }];
      };
      # bash pulls a gnu build compiler (depsBuildBuild, for build-time codegen
      # like mkbuiltins/mksignames) whose bare `gcc`/`cc` shadow the unpin host
      # wrapper (same names, earlier in PATH). Two fixes:
      #   - CC=<host wrapper abspath> via makeFlags+env: configure substitutes
      #     CC=gcc into the Makefile (it resolves to the gnu cc, which can't do
      #     the static-musl link — `-lreadline`/`-lc` missing), so pin CC for
      #     both configure detection and the make link.
      #   - CC_FOR_BUILD=gcc -std=gnu17: the build-tool compiles run on the gnu
      #     gcc; gcc-15 defaults to C23 where bash-5.3's `typedef unsigned char
      #     bool` is rejected, so force gnu17 there.
      # (coreutils/grep/sed have no build compiler, so they don't hit this.)
      #
      # These workarounds apply on EVERY linux build (native AND cross),
      # because the engine is active on all of linux (the lib's `useEngine =
      # engine == "unpin-llvm" && hostPlatform.isLinux`). The engine cc-wrapper
      # has `targetPrefix = ""`, so on a cross build its unprefixed `gcc`/`cc`
      # shadow the depsBuildBuild build gcc; without an explicit `CC` pin bash's
      # configure picks the wrong one and links the target binary with the
      # build toolchain (`ld.bfd: cannot find -lreadline`). Pin CC to the engine
      # wrapper (the stdenv IS the engine on cross too now), which matches the
      # stdenv — so the old "C compiler cannot create executables" hazard
      # (which only applied when cross kept the DEFAULT gcc stdenv) is gone.
      # darwin/windows keep plain pkgsStatic (handled by the lib elsewhere).
      build = pkgs:
        let
          base = pkgs.pkgsStatic.bash;
          host = base.stdenv.hostPlatform;
          buildp = base.stdenv.buildPlatform;
          cc = base.stdenv.cc;
          isCross = buildp.system != host.system;
          # CC_FOR_BUILD must yield RUNNABLE build-host executables (bash's
          # mkbuiltins/mksignames codegen runs during the build). The engine
          # target cc is `-target <host>` and can't run on the builder, and on
          # cross its unprefixed `gcc`/`cc` are ambiguous with the build gcc.
          # Pin the build-platform gcc by abspath on cross; native keeps the
          # bare `gcc` (build == host, no ambiguity) to stay byte-identical to
          # the published native build.
          ccForBuild = if isCross then "${pkgs.buildPackages.stdenv.cc}/bin/cc" else "gcc";
        in
        if !host.isLinux then base
        else base.overrideAttrs (old: {
          preConfigure = (old.preConfigure or "") + ''
            export CC=${cc}/bin/cc
            export CXX=${cc}/bin/c++
          '';
          makeFlags = (old.makeFlags or [ ]) ++ [ "CC=${cc}/bin/cc" ];
          # CC_FOR_BUILD has a space, so it can't ride in `makeFlags` (those
          # are word-split — make would see `-std=gnu17` as a stray option).
          # `makeFlagsArray` is a real bash array that preserves the space.
          preBuild = (old.preBuild or "") + ''
            makeFlagsArray+=( "CC_FOR_BUILD=${ccForBuild} -std=gnu17" )
          '';
        });

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
