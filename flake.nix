{
  description = "bash as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Windows goes through Cosmopolitan, not mingw: mingw lacks the fork()/signals
  # bash's job control needs. Cosmocc emulates fork() via CreateProcessW.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "bash";
      # No doCheck: bash's `make check` is a diff harness that exits 0 even on
      # anomalies, so it can't gate a release; it also assumes a full FHS the
      # sandbox lacks. The smoke (`bash --version`) is the floor.
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };

      # bash's `main` is 3-arg — main(argc, argv, env), reading the environment
      # from the THIRD param; the mega dispatcher calls applets as
      # fn(argc, argv, environ) precisely so this works.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "bash"; aliases = [ "sh" ]; }];
      };
      # The CC_FOR_BUILD=gnu17 build fix (bash-5.3's mkbuiltins/mksignames
      # codegen breaks under C23) lives in nix-lib's native-overlay/bash.nix —
      # single source of truth, so the engine's all-deps path can't drift from
      # it when another package drags bash in. No-op off Linux.
      # This multicall ships only bash (aliased sh) — not bashbug, the bug-report
      # shell script. nixpkgs installs bashbug's man page too, so drop it: the
      # engine man-set should embed exactly the shipped program's page (bash.1),
      # not a phantom bashbug.1.
      build = pkgs:
        (unpins-lib.lib.nativeFixes.bash pkgs.pkgsStatic).overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            for _mo in $outputs; do
              rm -f "''${!_mo}"/share/man/man1/bashbug.1*
            done
          '';
        });

      # Cosmo (APE/Windows) multicall module for the mega. Cosmo has no link
      # sidecar, so inputs stay hand-listed (unlike inferLinkInputs above).
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
