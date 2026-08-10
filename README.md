# mkscript

`mkscript` creates executable Bash script skeletons without overwriting existing files.

## Features

- Creates an executable file at the path you request.
- Writes `#!/usr/bin/env bash` by default.
- Adds `set -euo pipefail` when you pass `-s` or `--strict`.
- Optionally creates a global shortcut in `~/.local/bin` when you pass `-g` or `--global`.
- Can link an existing local script into `~/.local/bin` when you pass `-l` or `--link`.
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

Global shortcut:

```bash
mkscript test -g
```

This creates `./test` and a symlink at `~/.local/bin/test` pointing back to it.

Flags can be mixed in either order:

```bash
mkscript -g test -s
mkscript -s test -g
```

Both commands create the same strict-mode script and global shortcut.

Link an existing local script later:

```bash
mkscript -l test
mkscript test.sh -l
```

`mkscript` asks for confirmation before it creates the shortcut.

Other commands:

```bash
mkscript --help
mkscript --version
```

## Exit codes

- `0`: success
- `64`: command-line usage error
- `73`: could not create the requested script safely

## Global mode notes

- `-g` and `--global` use the script basename for the shortcut name.
- `mkscript` creates the shortcut in `~/.local/bin`.
- Existing files or symlinks at that global path are never overwritten.
- `~/.local/bin` needs to be on your `PATH` if you want to run the shortcut directly.

## Link-only mode notes

- `-l` and `--link` only create the global shortcut; they do not create or edit the local file.
- The local target must already exist and must not be a directory.
- `mkscript` prompts with `Are you sure you want to link source path '<source-path>' to '<bin-location>'?`.
- `-l` cannot be combined with `-g` or `-s`.

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

- `mkscript-1.0.1.tar.gz`
- `mkscript_1.0.1-1_all.deb`
- `mkscript-1.0.1-1.fc42.noarch.rpm`
- `mkscript-1.0.1-1.fc42.src.rpm`
- `mkscript_1.0.1-1_arm64.buildinfo`
- `mkscript_1.0.1-1_arm64.changes`
- checksums and build metadata

## Install from release artifacts

Debian and Ubuntu:

```bash
sudo apt install ./mkscript_1.0.1-1_all.deb
```

Fedora:

```bash
sudo dnf install ./mkscript-1.0.1-1.fc42.noarch.rpm
```

RHEL, Rocky Linux, AlmaLinux, and systems using `yum`:

```bash
sudo yum install ./mkscript-1.0.1-1.fc42.noarch.rpm
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
- `.github/workflows/release.yml` builds release artifacts and publishes them for version tags such as `v1.0.1`.
