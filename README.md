# bash

[bash](https://www.gnu.org/software/bash/) as a single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/bash/actions/workflows/bash.yml/badge.svg)](https://github.com/unpins/bash/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install bash`.

## Usage

Run the `bash` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin bash -c 'echo hello'
unpin bash --version
```

To install it onto your PATH:

```bash
unpin install bash
```

## Man pages

`bash.1` is embedded in the binary — read it with `unpin man bash`. `bashbug` (the bug-report shell script) isn't shipped, so its page isn't embedded.

## Build locally

```bash
nix build github:unpins/bash
./result/bin/bash --version
```

Or run directly:

```bash
nix run github:unpins/bash
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/bash/releases) page has standalone binaries for manual download.

## Build notes

- **Aliases:** `unpin install bash` also creates `sh`. Started under that name, bash runs in POSIX mode.
- **Windows** uses [Cosmopolitan](https://justine.lol/cosmopolitan/), not mingw: bash's job control needs `fork()` and POSIX signal semantics, which mingw does not provide.
- **Line editing** works without a host `/usr/share/terminfo`: common terminal descriptions are built in. On Linux and macOS the system's terminfo still wins when present.
- **Not included:** loadable builtins (`enable -f` needs dynamic loading, which a single self-contained binary does not do); translated messages (no message catalogs ship, so bash speaks English).
- **Tests:** bash's `make check` is not run: it exits 0 whatever its diffs show, so it cannot fail a build, and it expects a full FHS (`/bin/echo`, …) the build sandbox lacks.
