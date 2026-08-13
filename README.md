# bash

[bash](https://www.gnu.org/software/bash/) as a single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/bash/actions/workflows/bash.yml/badge.svg)](https://github.com/unpins/bash/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install bash`.

Linux/macOS use `pkgsStatic`. Windows is built via [Cosmopolitan](https://justine.lol/cosmopolitan/) (cosmocc cross-toolchain inside Nix) because mingw lacks the `fork()`/signal semantics bash's job control depends on. Cosmocc implements `fork()` on Windows via `CreateProcessW` + page copy.

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

## Man pages

`bash.1` is embedded in the binary — read it with `unpin man bash`. `bashbug` (the bug-report shell script) isn't shipped, so its page isn't embedded.

## Build notes

- **Aliases:** `unpin install bash` also creates `sh`. Started under that name, bash runs in POSIX mode.
- **Tests:** bash's `make check` is not run. It's a diff-based harness — it prints "possible anomaly" diffs but exits 0 regardless, so it can't gate a release, and it assumes a full FHS the build sandbox lacks (`/bin/echo`, …). The `bash --version` smoke test is the floor.
