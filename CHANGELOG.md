# Changelog

All notable changes to this project are documented in this file.

## [1.5.0] - 2026-08-12

### Added

- Add the native Windows PowerShell implementation with `.cmd` generation and managed global wrappers.
- Add Windows CI, installer/uninstaller commands, release ZIP packaging, and a standalone executable launcher.
- Add a checksum-verifying direct installer plus WinGet and Chocolatey package generation and publishing automation.

### Changed

- Document Windows installation, command lookup, global wrapper management, and package publishing.

## [1.4.4] - 2026-08-12

### Changed

- Simplify global linking workflow

## [1.4.3] - 2026-08-12

### Changed

- Add glob patterns to mkscript file lookup

## [1.4.2] - 2026-08-11

### Changed

- Automate patch releases from successful main CI
- Add workflow concurrency and lookup directories

## [1.4.1] - 2026-08-11

### Fixed

- RPM `%check` now keeps the unreadable-directory `-f` test valid when the package test suite runs as `root` in GitHub Actions and `rpmbuild`.

## [1.4.0] - 2026-08-11

### Added

- `-f name1 [name2 ... name9]` lookup mode to resolve commands, local files, and indexed filenames.
- `printf '%s\n' name1 name2 | mkscript -f` support for newline-separated lookup input from standard input.

### Changed

- `-f` now supports both local tree listing and lookup mode while keeping depth values `0` through `9` for listing.
- `INSTALL.md`, the man page, and packaged metadata now document lookup mode, exit codes, and the updated `-f` behavior consistently.

## [1.3.0] - 2026-08-10

### Added

- `--template terraform` and `--template ansible` starter file support.
- `-mv` to move an existing Bash script, preserve its permission mode, and recreate its managed global shortcut when needed.
- `-f` and `--files` to list matching current-tree files in a readable table with kind, executable state, and global-link state.

### Changed

- Help text, README examples, and the man page now document template, move, and file-listing modes.
- Packaging metadata and generated Homebrew formula content now reflect the expanded Bash, Terraform, and Ansible feature set.

## [1.2.0] - 2026-08-10

### Added

- A default comment header for every newly created script with script name, blank description line, creation date, and creator login name.

### Changed

- Homebrew formula tests now validate the generated header content line by line.
- Documentation and packaging smoke tests now reflect the new default script layout.

## [1.1.0] - 2026-08-10

### Added

- `-c` to check whether the expected global link exists and print its path.
- `-r` to remove an existing global link after confirmation.
- Homebrew formula generation, tap publishing automation, and macOS formula validation in CI.

### Changed

- macOS now prefers a personal local bin directory already on `PATH` before falling back to `~/.local/bin`.
- Documentation, packaging metadata, and tests now cover create, link, check, and remove workflows.

## [1.0.1] - 2026-08-10

### Added

- Global shortcut creation through `-g` and `--global`.
- Link-only shortcut mode through `-l` and `--link`.
- Confirmation prompt for link-only mode.

### Changed

- Flag parsing now accepts flexible ordering for `-s`, `-g`, and `-l` where supported.
- Documentation and packaging metadata now reflect the new shortcut workflows.

## [1.0.0] - 2026-08-10

### Added

- Initial `mkscript` CLI with `-s` and `--strict` support.
- Safe refusal to overwrite existing paths.
- Automated tests for success cases and failure paths.
- Debian and RPM packaging.
- GitHub Actions CI and release automation.
- Documentation for upstream release and distro inclusion workflows.
