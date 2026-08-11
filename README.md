# mkscript

`mkscript` creates Bash, Terraform, and Ansible starter files without overwriting existing paths.

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

- Creates Bash, Terraform, or Ansible starter files at the path you request.
- Uses Bash by default and writes `#!/usr/bin/env bash` plus a default comment header with script name, blank description, creation date, and creator.
- Adds `set -euo pipefail` when you pass `-s` or `--strict` with the Bash template.
- Can create a Terraform starter file with `--template terraform`.
- Can create an Ansible playbook starter file with `--template ansible`.
- Optionally creates a global shortcut in your detected user bin directory when you pass `-g` or `--global` with the Bash template.
- Can list matching files in the current folder tree with `-f` or `--files`, including shell-style files, executable files, and globally linked local files.
- Can move an existing local Bash script with `-mv`, preserve its permission mode, and recreate the global shortcut when needed.
- Can link an existing local Bash file into that same user bin directory when you pass `-l` or `--link`.
- Can check an expected global Bash shortcut with `-c`.
- Can remove an existing global Bash shortcut with `-r`.
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

Terraform starter:

```bash
mkscript --template terraform main.tf
```

This creates:

```hcl
# File: main.tf
# Description:
# Created: YYYY-MM-DD
# Creator: login-user

terraform {
  required_version = ">= 1.0.0"
}
```

Ansible starter:

```bash
mkscript site.yml --template ansible
```

This creates:

```yaml
# File: site.yml
# Description:
# Created: YYYY-MM-DD
# Creator: login-user

---
- name: site.yml
  hosts: all
  gather_facts: false
  tasks: []
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

List matching files under the current folder tree:

```bash
mkscript -f
```

Limit file listing to the current folder only:

```bash
mkscript -f 0
```

Limit file listing to one subfolder deep:

```bash
mkscript --files 1
```

This prints a table like:

```text
PATH                  KIND     EXEC  GLOBAL
./scripts/build.sh    sh+exec  yes   no
./hooks/pre-commit    exec     yes   yes
./tools/deploy.sh     sh       no    yes
```

Move an existing Bash script to a new path:

```bash
mkscript -mv test deploy
```

If `test` already had a global shortcut, `mkscript` moves the local file, preserves its permission mode, removes the old shortcut, and creates a new shortcut for `deploy`.

Create a new global shortcut during the move even when the source was not linked before:

```bash
mkscript -mv test deploy -g
```

Other commands:

```bash
mkscript --help
mkscript --version
```

Template selection also works in either order:

```bash
mkscript --template terraform main.tf
mkscript main.tf -t terraform
mkscript -t ansible site.yml
mkscript site.yml --template ansible
```

## Exit codes

- `0`: success
- `64`: command-line usage error
- `1`: checked or removal target was not present
- `73`: could not create the requested script safely

## Global mode notes

- `-g` and `--global` use the script basename for the shortcut name.
- Global shortcuts are supported only for the Bash template.
- `-mv ... -g` creates a new global shortcut for the move target even when the source was not linked already.
- On Linux, `mkscript` uses `~/.local/bin` for global shortcuts.
- On macOS, `mkscript` prefers a personal `*local*/bin` or `~/bin` entry already on `PATH`, then falls back to `~/.local/bin`.
- Existing files or symlinks at that global path are never overwritten.
- The chosen global bin directory needs to be on your `PATH` if you want to run the shortcut directly.

## Link-only mode notes

- `-l` and `--link` only create the global shortcut; they do not create or edit the local file.
- The local target must already exist and must not be a directory.
- `mkscript` prompts with `Are you sure you want to link source path '<source-path>' to '<bin-location>'?`.
- `-l` only supports the Bash template.
- `-l` cannot be combined with `-g` or `-s`.

## Link management notes

- `-c` checks for the expected global shortcut and prints the resolved shortcut path when it exists.
- `-r` prompts with `Are you sure you want to remove link for '<script-name>' from '<bin-location>'?`.
- `-r` only removes symlinks; it refuses to delete regular files or directories at the global path.
- `-c` and `-r` only support the Bash template.
- `-c` and `-r` cannot be combined with `-g`, `-l`, or `-s`.

## Files mode notes

- `-f` and `--files` scan the current folder and all subdirectories by default.
- `-f 0` limits the scan to the current folder only.
- `-f 1` through `-f 9` include that many subfolder levels.
- A file is listed if it ends with `.sh`, is executable, or is the local target of a managed global symlink.
- `PATH` shows the relative file path.
- `KIND` is `sh`, `exec`, `sh+exec`, or `file`.
- `EXEC` shows whether the local file is executable.
- `GLOBAL` shows whether a managed global symlink points to that local file.
- Unreadable folders are skipped quietly so protected macOS paths do not clutter the output.
- `-f` is read-only and cannot be combined with `--template`, `-g`, `-mv`, `-s`, `-l`, `-c`, or `-r`.

## Move mode notes

- `-mv` only supports the Bash template.
- `-mv` moves the existing local file instead of rewriting its contents.
- `-mv` preserves the source file's permission mode on the moved target.
- If the source had a managed global shortcut, `-mv` removes the old shortcut and recreates it for the target basename.
- `-mv` can be combined with `-g` to create a new global shortcut for an unlinked source.
- `-mv` cannot be combined with `-s`, `-l`, `-c`, or `-r`.

## Template notes

- `--template bash` is the default behavior.
- `--template terraform` creates a non-executable `.tf` starter file.
- `--template ansible` creates a non-executable YAML playbook starter file.
- `-s`, `-g`, `-mv`, `-l`, `-c`, and `-r` are Bash-only options.

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
