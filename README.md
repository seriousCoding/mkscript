# mkscript

`mkscript` creates executable Bash script skeletons without overwriting existing files.

Quick links: [`INSTALL.md`](INSTALL.md) | [Public install site](https://seriouscoding.github.io/install/) | [Releases](https://github.com/seriousCoding/mkscript/releases) | [Checksums](https://github.com/seriousCoding/mkscript/releases/latest/download/SHA256SUMS) | [Official packaging guide](docs/official-package-inclusion.md)

## Install

macOS with Homebrew:

```bash
brew install seriousCoding/tap/mkscript
```

Debian and Ubuntu:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.deb
sudo apt install ./mkscript.deb
```

Fedora:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo dnf install ./mkscript.rpm
```

RHEL, Rocky Linux, AlmaLinux, and other `yum`-based systems:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo yum install ./mkscript.rpm
```

Verify the install:

```bash
mkscript --version
mkscript --help
```

For versioned package links, checksum verification, and platform-specific notes, see [`INSTALL.md`](INSTALL.md) and the [public install page](https://seriouscoding.github.io/install/).

## Features

- Creates an executable file at the path you request.
- Writes `#!/usr/bin/env bash` plus a default comment header with script name, blank description, creation date, and creator.
- Adds `set -euo pipefail` when you pass `-s` or `--strict`.
- Optionally creates a global shortcut in your detected user bin directory when you pass `-g` or `--global`.
- Can link an existing local script into that same user bin directory when you pass `-l` or `--link`.
- Can check an expected global shortcut with `-c`.
- Can remove an existing global shortcut with `-r`.
- Refuses to overwrite existing files, symlinks, or directories.
- Ships with tests, a man page, Debian packaging, RPM packaging, Homebrew support, and GitHub Actions automation.

## Usage

```bash
mkscript hello-world
```

This creates `./hello-world` with:

```bash
#!/usr/bin/env bash
# Script: hello-world
# Description:
# Created: YYYY-MM-DD
# Creator: login-user
```

Strict mode:

```bash
mkscript --strict deploy.sh
```

This creates:

```bash
#!/usr/bin/env bash
# Script: deploy.sh
# Description:
# Created: YYYY-MM-DD
# Creator: login-user
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

Check whether a global shortcut already exists:

```bash
mkscript -c test
mkscript test -c
```

If the shortcut exists, `mkscript` prints its path and exits successfully.

Remove an existing global shortcut later:

```bash
mkscript -r test
mkscript test -r
```

`mkscript` asks for confirmation before it removes the shortcut.

Other commands:

```bash
mkscript --help
mkscript --version
```

## Exit codes

- `0`: success
- `64`: command-line usage error
- `1`: checked or removal target was not present
- `73`: could not create the requested script safely

## Global mode notes

- `-g` and `--global` use the script basename for the shortcut name.
- On Linux, `mkscript` uses `~/.local/bin` for global shortcuts.
- On macOS, `mkscript` prefers a personal `*local*/bin` or `~/bin` entry already on `PATH`, then falls back to `~/.local/bin`.
- Existing files or symlinks at that global path are never overwritten.
- The chosen global bin directory needs to be on your `PATH` if you want to run the shortcut directly.

## Link-only mode notes

- `-l` and `--link` only create the global shortcut; they do not create or edit the local file.
- The local target must already exist and must not be a directory.
- `mkscript` prompts with `Are you sure you want to link source path '<source-path>' to '<bin-location>'?`.
- `-l` cannot be combined with `-g` or `-s`.

## Link management notes

- `-c` checks for the expected global shortcut and prints the resolved shortcut path when it exists.
- `-r` prompts with `Are you sure you want to remove link for '<script-name>' from '<bin-location>'?`.
- `-r` only removes symlinks; it refuses to delete regular files or directories at the global path.
- `-c` and `-r` cannot be combined with `-g`, `-l`, or `-s`.

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

- `mkscript-<version>.tar.gz`
- `mkscript_<version>-1_all.deb`
- `mkscript-<version>-1.fc42.noarch.rpm`
- `mkscript-<version>-1.fc42.src.rpm`
- `mkscript.tar.gz`
- `mkscript.deb`
- `mkscript.rpm`
- `mkscript.src.rpm`
- `mkscript.rb`
- Debian build metadata and `.changes` files
- checksums and build metadata

## Install from release artifacts

Debian and Ubuntu:

```bash
sudo apt install ./mkscript_<version>-1_all.deb
```

Fedora:

```bash
sudo dnf install ./mkscript-<version>-1.fc42.noarch.rpm
```

RHEL, Rocky Linux, AlmaLinux, and systems using `yum`:

```bash
sudo yum install ./mkscript-<version>-1.fc42.noarch.rpm
```

## Stable GitHub download URLs

These alias filenames stay the same across releases, so users can keep the same GitHub download command:

Debian and Ubuntu:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.deb
sudo apt install ./mkscript.deb
```

Fedora:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo dnf install ./mkscript.rpm
```

RHEL, Rocky Linux, AlmaLinux, and systems using `yum`:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo yum install ./mkscript.rpm
```

## Documentation

- [`INSTALL.md`](INSTALL.md): direct install commands for macOS, Debian, Ubuntu, Fedora, RHEL, Rocky Linux, and AlmaLinux
- [https://seriouscoding.github.io/install/](https://seriouscoding.github.io/install/): public install landing page
- [`docs/official-package-inclusion.md`](docs/official-package-inclusion.md): Debian, Ubuntu, Fedora, and EPEL inclusion path
- [GitHub releases](https://github.com/seriousCoding/mkscript/releases): packaged downloads and source archives
- [SHA256SUMS](https://github.com/seriousCoding/mkscript/releases/latest/download/SHA256SUMS): current release checksums

## Repository layout

- `src/`: CLI source template
- `test/`: automated tests
- `debian/`: Debian packaging
- `packaging/rpm/`: RPM spec
- `docs/`: project documentation, including distro inclusion guidance
- `scripts/`: build, packaging, and checksum helpers

## Release automation

- `.github/workflows/ci.yml` runs tests and shell linting.
- `.github/workflows/tag-from-version.yml` creates a missing `vX.Y.Z` tag from `VERSION` after `ci` succeeds on `main`, then explicitly starts the release workflow.
- `.github/workflows/release.yml` builds release artifacts, publishes them for the matching `vX.Y.Z` tag, and can update the Homebrew tap when a token is configured.
