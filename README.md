# mkscript

`mkscript` creates complete, editable command-script, Bash, Dockerfile, Docker Compose, Kubernetes, Terraform, Ansible, and Helm starters without overwriting existing paths. It uses native Bash on Linux/macOS and a native PowerShell implementation on Windows.

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

Windows (PowerShell):

```powershell
winget install --id seriousCoding.mkscript --exact
# or
choco install mkscript -y
```

The catalog commands become available after their initial WinGet and Chocolatey submissions are approved. The direct installer works immediately from a published GitHub release:

```powershell
irm https://raw.githubusercontent.com/seriousCoding/mkscript/main/install.ps1 | iex
```

Open a new terminal after a direct installation, then run `mkscript --version`. To remove it later, run `%LOCALAPPDATA%\Programs\mkscript\uninstall.cmd`.

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

- On Linux and macOS, creates Bash starter files by default with `#!/usr/bin/env bash` and the standard metadata header.
- On Windows, creates `.cmd` starter files by default with `@echo off` and the same metadata header rendered as `rem` comments.
- `-s` and `--strict` add `set -euo pipefail` for Bash on Linux/macOS and `setlocal EnableExtensions EnableDelayedExpansion` for `.cmd` on Windows.
- `--template terraform`, `--template ansible`, `--template dockerfile` (or `docker`), `--template docker-compose`, and `--template helm` work on every platform.
- Built-in Kubernetes starter templates work on every platform for `k8s-namespace`, `k8s-pod`, `k8s-deployment`, `k8s-service`, `k8s-configmap`, `k8s-secret`, `k8s-ingress`, `k8s-networkpolicy`, `k8s-serviceaccount`, `k8s-role`, `k8s-rolebinding`, `k8s-clusterrole`, `k8s-clusterrolebinding`, `k8s-persistentvolume`, `k8s-persistentvolumeclaim`, `k8s-storageclass`, `k8s-statefulset`, `k8s-daemonset`, `k8s-job`, `k8s-cronjob`, and `k8s-horizontalpodautoscaler`.
- Windows supports `cmd` plus the non-script templates above. It does not support `--template bash`.
- `-g`, `-c`, `-r`, and `-mv` manage Bash symlinks on Linux/macOS and managed `.cmd` wrappers on Windows.
- `-f` and `--files` list or look up platform-native commands and files.
- Omitted template targets use a standard name and require confirmation. Explicit extensionless targets add the template extension except Dockerfiles and Helm chart directories.
- Refuses to overwrite existing files, chart directories, symlinks, directories, or managed wrapper paths.
- Ships with tests, a man page, Debian packaging, RPM packaging, Homebrew support, and GitHub Actions automation.
- Generates WinGet and Chocolatey metadata and can publish catalog updates from tagged releases when repository credentials are configured.

## Usage

When no target is supplied, `mkscript` prompts before creating the standard target and prints the explicit alternative. For example, `mkscript -t docker` creates `Dockerfile` after confirmation and prints `mkscript -t docker Dockerfile`. Declining leaves the filesystem unchanged.

| Template | Default target | Extension added to explicit extensionless targets |
| --- | --- | --- |
| Bash (Unix) | `script.sh` | `.sh` when `-t bash` is selected; the default `mkscript NAME` keeps the supplied Unix script name for compatibility |
| CMD (Windows) | `script.cmd` | `.cmd` |
| Terraform | `main.tf` | `.tf` |
| Ansible | `site.yml` | `.yml` |
| Dockerfile / Docker | `Dockerfile` | none |
| Docker Compose | `docker-compose.yml` | `.yml` |
| Kubernetes | resource name plus `.yaml` | `.yaml` |
| Helm | `chart` directory | none |

```bash
mkscript hello-world
```

On Linux and macOS this creates `./hello-world` with:

```bash
#!/usr/bin/env bash
# Script: hello-world
# Description:
# Created: YYYY-MM-DD
# Creator: login-user
```

On Windows the same command creates `.\hello-world.cmd` with `@echo off` followed by the same metadata header in `rem` comments.

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

On Windows, `mkscript --strict deploy` creates `deploy.cmd` and adds `setlocal EnableExtensions EnableDelayedExpansion` after the metadata header.

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

Dockerfile starter:

```bash
mkscript --template docker
```

Docker Compose starter:

```bash
mkscript --template docker-compose
```

Kubernetes Deployment starter:

```bash
mkscript --template k8s-deployment deployment.yaml
```

Helm chart starter:

```bash
mkscript --template helm service-chart
helm lint service-chart
helm template service-chart service-chart
```

The generated chart includes `Chart.yaml`, `values.yaml`, `.helmignore`, helpers, deployment, service, service account, ingress, autoscaling, network policy, persistent volume claim, config map, secret, notes, and a Helm test pod. Values expose image, service, resources, security contexts, ingress, persistence, autoscaling, network policy, configuration, secret references, and scheduling controls.

Docker Compose includes a service, restart policy, health check, resource limits, named volume, and named bridge network. Kubernetes templates include a complete editable manifest for each supported resource; update cluster-specific values such as ingress classes, storage provisioners, host paths, and credentials before applying them.

Global shortcut:

```bash
mkscript test -g
```

On Linux and macOS this creates `./test` and a symlink at `~/.local/bin/test` pointing back to it.

On Windows this creates `test.cmd` plus a command wrapper in `%LOCALAPPDATA%\mkscript\bin`. Add that directory to `PATH` once; wrappers do not require symlink privileges.

Flags can be mixed in either order:

```bash
mkscript -g test -s
mkscript -s test -g
```

Both commands create the same strict-mode script and global shortcut or wrapper.

Link an existing local script later:

```bash
mkscript -g test
mkscript test.sh -g
```

If the local path already exists, `mkscript` asks for confirmation before it creates the shortcut or wrapper and does not rewrite the file.

Check whether a global shortcut or wrapper already exists:

```bash
mkscript -c test
mkscript test -c
```

If the shortcut or wrapper exists, `mkscript` prints its path and exits successfully.

Remove an existing global shortcut or wrapper later:

```bash
mkscript -r test
mkscript test -r
```

`mkscript` asks for confirmation before it removes the shortcut or wrapper.

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

Look up one or more commands or filenames and print the resolved location plus its parent directory:

```bash
mkscript -f bash README.md
```

Look up names from a pipe:

```bash
printf '%s\n' bash README.md | mkscript -f
```

Lookup mode prints a table with `QUERY`, `FOUND`, `TYPE`, `LOCATION`, and `DIRECTORY`.

On Linux and macOS, listing mode prints a table like:

```text
PATH                  KIND     EXEC  GLOBAL
./scripts/build.sh    sh+exec  yes   no
./hooks/pre-commit    exec     yes   yes
./tools/deploy.sh     sh       no    yes
```

On Windows, listing mode prints `PATH` and `KIND` for files such as `.cmd`, `.bat`, `.ps1`, and `.sh`.

Move an existing script to a new path:

```bash
mkscript -mv test deploy
```

`mkscript` asks for confirmation before moving. If the target is an existing directory, it retains the source basename, so `mkscript -mv myfile myscripts` moves `myfile` to `myscripts/myfile`.

If `test` already had a managed global shortcut or wrapper, `mkscript` moves the local file, removes the old shortcut or wrapper, and creates a new one for `deploy`. On Linux and macOS it preserves the source permission mode unless `-g` is supplied; `-mv -g` makes the moved target executable before creating its global shortcut.

Create a new global shortcut or wrapper during the move even when the source was not linked before:

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
mkscript --template dockerfile Dockerfile
mkscript deployment.yaml --template k8s-deployment
```

## Exit codes

- `0`: success
- `64`: command-line usage error
- `1`: checked or removal target was not present, or one or more lookup names were not found
- `73`: could not create the requested script safely

## Global mode notes

- Linux and macOS create POSIX symlinks and otherwise retain their existing behavior.
- Windows creates managed `.cmd` wrappers in `%LOCALAPPDATA%\mkscript\bin` (override with `MKSCRIPT_BIN_DIR`). `-c`, `-r`, and `-mv` inspect, remove, and update those wrappers.
- `-g` and `--global` use the script basename for the shortcut name.
- On Linux and macOS, global shortcuts are supported only for the Bash template.
- On Windows, wrapper creation for a new file is supported only for the `cmd` template.
- If the requested path does not exist yet, `-g` creates the new Bash file and its global shortcut on Linux/macOS, or the new `.cmd` file and its wrapper on Windows.
- If the requested path already exists locally, `-g` switches to existing-file link mode, prompts for confirmation, and creates only the global shortcut or wrapper.
- Existing-file global mode does not rewrite the local file.
- Existing-file global mode requires a local path that already exists and is not a directory.
- Existing-file global mode cannot be combined with `-s`.
- `-mv ... -g` creates a new global shortcut or wrapper for the move target even when the source was not linked already. On Linux/macOS it also makes the moved target executable.
- Every `-mv` operation asks for confirmation and accepts an existing directory target, retaining the source basename inside that directory.
- On Linux, `mkscript` uses `~/.local/bin` for global shortcuts.
- On macOS, `mkscript` prefers a personal `*local*/bin` or `~/bin` entry already on `PATH`, then falls back to `~/.local/bin`.
- On Windows, `mkscript` uses `%LOCALAPPDATA%\mkscript\bin` unless `MKSCRIPT_BIN_DIR` is set.
- Existing files, symlinks, or wrappers at that global path are never overwritten.
- The chosen global bin directory needs to be on your `PATH` if you want to run the shortcut directly.

## Link management notes

- `-c` checks for the expected global shortcut or wrapper and prints the resolved path when it exists.
- `-r` prompts before removing the managed symlink or wrapper.
- `-r` only removes managed symlinks on Linux/macOS and managed wrappers on Windows. It refuses to delete unrelated paths at the global location.
- `-c` resolves the Bash symlink name on Linux/macOS and the `.cmd` wrapper name on Windows.
- On Windows, `-c` cannot be combined with `-g` or `-s`.

## Files mode notes

- `-f` and `--files` scan the current folder and all subdirectories by default.
- `-f 0` limits the scan to the current folder only.
- `-f 1` through `-f 9` include that many subfolder levels.
- `-f name1 [name2 ...]` switches to lookup mode for one to nine names.
- `printf '%s\n' name1 name2 | mkscript -f` also uses lookup mode from newline-separated stdin.
- Quoted shell-style glob patterns like `mkscript -f 'install-wifi*'` are supported in lookup mode.
- Quote glob patterns so your shell passes them to `mkscript` unchanged.
- On Linux and macOS, a file is listed if it ends with `.sh`, is executable, or is the local target of a managed global symlink.
- On Windows, a file is listed if it ends with `.cmd`, `.bat`, `.ps1`, or `.sh`.
- On Linux and macOS, `PATH` shows the relative file path, `KIND` is `sh`, `exec`, `sh+exec`, or `file`, `EXEC` shows whether the file is executable, and `GLOBAL` shows whether a managed global symlink points to that local file.
- On Windows, listing mode prints `PATH` and `KIND`, where `KIND` is the extension without the leading dot.
- Unreadable folders are skipped quietly so protected macOS paths do not clutter the output.
- Lookup mode prints `QUERY`, `FOUND`, `TYPE`, `LOCATION`, and `DIRECTORY`.
- Lookup mode checks an exact path first, then exact or pattern command matches on `PATH`, then current-tree and wider filename matches.
- Lookup mode returns the first resolved match for each query.
- Lookup mode returns `0` only when every requested name is found, and `1` when any requested name is missing.
- Lookup mode accepts at most nine names total across arguments and piped stdin.
- A single numeric argument from `0` to `9` keeps its depth meaning; if you need lookup input from stdin, do not combine it with a depth argument.
- `-f` is read-only and cannot be combined with `--template`, `-g`, `-mv`, `-s`, `-c`, or `-r`.

Quoted glob lookup example:

```bash
mkscript -f 'install-wifi*'
```

## Move mode notes

- `-mv` supports the Bash template on Linux/macOS and the `cmd` template on Windows.
- `-mv` moves the existing local file instead of rewriting its contents.
- On Linux and macOS, `-mv` preserves the source file's permission mode on the moved target.
- If the source had a managed global shortcut or wrapper, `-mv` removes the old one and recreates it for the target basename.
- `-mv` can be combined with `-g` to create a new global shortcut or wrapper for an unlinked source.
- `-mv` cannot be combined with `-s`, `-c`, or `-r`.

## Template notes

- On Linux and macOS, `--template bash` is the default behavior.
- On Windows, `--template cmd` is the default behavior.
- `--template terraform` creates a non-executable `.tf` starter file.
- `--template ansible` creates a non-executable YAML playbook starter file.
- `--template dockerfile` creates a non-executable Dockerfile starter.
- `--template docker-compose` creates a non-executable Compose YAML starter.
- Built-in Kubernetes templates on every platform are `k8s-namespace`, `k8s-pod`, `k8s-deployment`, `k8s-service`, `k8s-configmap`, `k8s-secret`, `k8s-ingress`, `k8s-networkpolicy`, `k8s-serviceaccount`, `k8s-role`, `k8s-rolebinding`, `k8s-clusterrole`, `k8s-clusterrolebinding`, `k8s-persistentvolume`, `k8s-persistentvolumeclaim`, `k8s-storageclass`, `k8s-statefulset`, `k8s-daemonset`, `k8s-job`, `k8s-cronjob`, and `k8s-horizontalpodautoscaler`.
- On Linux and macOS, `-s`, `-g`, `-mv`, `-c`, and `-r` are Bash-only options.
- On Windows, `-s` applies to the `cmd` template, `-g`, `-mv`, `-c`, and `-r` apply to the wrapper workflow, and `--template bash` is not supported.

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
- `.github/workflows/tag-from-version.yml` takes a successful `main` CI result, bumps the patch version, syncs release metadata, commits `chore(release): vX.Y.Z`, creates the matching tag, and explicitly starts the release workflow.
- `.github/workflows/release.yml` builds release artifacts, publishes them for the matching `vX.Y.Z` tag, and can update the Homebrew tap when a token is configured.
