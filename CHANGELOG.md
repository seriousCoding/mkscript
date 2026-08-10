# Changelog

All notable changes to this project are documented in this file.

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
