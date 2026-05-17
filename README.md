# bash

Standalone build of [bash](https://www.gnu.org/software/bash/).

[![CI](https://github.com/unpins/bash/actions/workflows/bash.yml/badge.svg)](https://github.com/unpins/bash/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux/macOS use `pkgsStatic`. Windows is built via [Cosmopolitan](https://justine.lol/cosmopolitan/) (cosmocc cross-toolchain inside Nix) because mingw lacks the `fork()`/signal semantics bash's job control depends on. Cosmocc implements `fork()` on Windows via `CreateProcessW` + page copy.

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin bash
```

Or run without installing:

```bash
unpin run bash
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

The [Releases](https://github.com/unpins/bash/releases) page has standalone binaries and a `.tar.zst` data archive (man pages) for manual download.
