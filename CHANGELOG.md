# Changelog

## [Unreleased]

### Fixed

- The Windows binary no longer embeds a man page for `bashbug`, which it does
  not ship. The 5.3p9-2 fix covered only Linux and macOS.
- Windows: `sh.exe`, a full path to it, or `SH.EXE` now start bash in POSIX
  mode, as a bare `sh` already did.
- The README now says that line editing works without a host terminfo, that
  `enable -f` and translated messages are not available, and states the test
  policy in the catalog's form.

## [5.3p9-2] - 2026-09-26

### Added

- `unpin install bash` now also creates `sh`. Started under that name bash runs
  in POSIX mode, as it does on any system where `sh` is bash.

### Fixed

- On Windows, a bare command name typed at the bash prompt now runs. Catalog
  programs install as `<name>.exe` and Cosmopolitan appends no suffix while
  searching `PATH`, so `ls` found nothing where `ls.exe` worked; a candidate
  that does not exist is now retried once with `.exe`.

- The embedded man set no longer carries `bashbug.1`, a page for the
  bug-report script this build does not ship.

### Changed

- Built by the same compiler as the rest of the catalog. The Linux x86_64
  binary grew from 1.6 MB to 1.9 MB; behaviour is unchanged.

- `nix build` downloads the binary and nothing else. Two dead paths were baked
  into it — the loadables dir `enable -f` searches and the bashdb include dir,
  neither of them shipped — and that reference dragged 259 MB of closure behind
  a 1.9 MB binary.
