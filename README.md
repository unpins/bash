# bash

Standalone build of [bash](https://www.gnu.org/software/bash/). Runs on any Linux or macOS without external dependencies.

Linux/Darwin only — Windows is architecturally infeasible (bash on Windows requires Cygwin/MSYS POSIX emulation, which is a process-tree singleton DLL incompatible with single-binary distribution). For a Windows shell, see [busybox-w32](https://frippery.org/busybox/).

## Installation

You can install this package instantly using the [unpin](https://github.com/unpins/unpin) package manager:

```bash
unpin bash
```

Or run it without installing:

```bash
unpin run bash
```

## Build locally

```bash
nix build github:unpins/bash
./result/bin/bash
```

Or, in one shot:

```bash
nix run github:unpins/bash
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual Download

Standalone binaries and data packages are available on the [Releases](https://github.com/unpins/bash/releases) page.
