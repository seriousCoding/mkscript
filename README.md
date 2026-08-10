# mkscript

`mkscript` creates executable Bash script skeletons without overwriting existing files.

## Features

- Creates an executable file at the path you request.
- Writes `#!/usr/bin/env bash` by default.
- Adds `set -euo pipefail` when you pass `-s` or `--strict`.
- Refuses to overwrite existing files, symlinks, or directories.
- Ships with tests, a man page, Debian packaging, RPM packaging, and GitHub Actions automation.

## Usage

```bash
mkscript hello-world
```

This creates `./hello-world` with:

```bash
#!/usr/bin/env bash
```

Strict mode:

```bash
mkscript --strict deploy.sh
```

This creates:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Other commands:

```bash
mkscript --help
mkscript --version
```

## Exit codes

- `0`: success
- `64`: command-line usage error
- `73`: could not create the requested script safely

## Build and test

```bash
make test
```

Optional shell linting:

```bash
make lint
```

## Packaging

Local package builds use Linux tooling. On macOS, the supplied scripts run those builds in Docker.

```bash
make package
```

Artifacts are written to `dist/`:

- `mkscript-1.0.0.tar.gz`
- `mkscript_1.0.0-1_all.deb`
- `mkscript-1.0.0-1.noarch.rpm`
- `mkscript-1.0.0-1.src.rpm`
- checksums and build metadata

## Install from release artifacts

Debian and Ubuntu:

```bash
sudo apt install ./mkscript_1.0.0-1_all.deb
```

Fedora:

```bash
sudo dnf install ./mkscript-1.0.0-1.noarch.rpm
```

RHEL, Rocky Linux, AlmaLinux, and systems using `yum`:

```bash
sudo yum install ./mkscript-1.0.0-1.noarch.rpm
```

## Repository layout

- `src/`: CLI source template
- `test/`: automated tests
- `debian/`: Debian packaging
- `packaging/rpm/`: RPM spec
- `docs/`: project documentation, including distro inclusion guidance
- `scripts/`: build, packaging, and checksum helpers

## Release automation

- `.github/workflows/ci.yml` runs tests and shell linting.
- `.github/workflows/release.yml` builds release artifacts and publishes them for version tags such as `v1.0.0`.
