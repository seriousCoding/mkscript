# Changelog

All notable changes to this project are documented in this file.

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
