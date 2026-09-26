# Changelog

## [Unreleased]

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
