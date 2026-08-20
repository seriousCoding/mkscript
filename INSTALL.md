# Install mkscript

`mkscript` creates executable script skeletons and optional user-bin shortcuts on Windows, macOS, and Linux.

Quick links: [Public install page](https://seriouscoding.github.io/install/) | [GitHub releases](https://github.com/seriousCoding/mkscript/releases) | [Latest checksums](https://github.com/seriousCoding/mkscript/releases/latest/download/SHA256SUMS) | [Homebrew tap](https://github.com/seriousCoding/homebrew-tap)

## Install mkscript on macOS

Install with Homebrew on either Apple Silicon or Intel:

```bash
brew install seriousCoding/tap/mkscript
```

Verify the install:

```bash
mkscript --version
mkscript --help
```

If you plan to use `-g`, make sure your chosen personal bin directory is on `PATH`. `mkscript` prefers `~/.local/bin`, `~/bin`, or another personal `*local*/bin` directory already present on `PATH`.

## Install mkscript on Windows

With WinGet (after its initial catalog submission is accepted):

```powershell
winget install --id seriousCoding.mkscript --exact
```

With Chocolatey (after community moderation):

```powershell
choco install mkscript -y
```

Directly from the latest GitHub release:

```powershell
irm https://raw.githubusercontent.com/seriousCoding/mkscript/main/install.ps1 | iex
```

The direct bootstrap downloads the stable Windows ZIP, verifies it against the release `SHA256SUMS`, and runs the included installer. For a manual install instead:

```powershell
Invoke-WebRequest https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript-windows-x64.zip -OutFile mkscript.zip
Expand-Archive mkscript.zip -DestinationPath .\mkscript-package -Force
.\mkscript-package\install.cmd
```

The installer copies the command to `%LOCALAPPDATA%\Programs\mkscript` and adds that directory plus `%LOCALAPPDATA%\mkscript\bin` to your user `PATH`. Open a new terminal afterward. Windows does not require Developer Mode or symlink privileges. `mkscript demo` writes `demo.cmd` by default.

Uninstall with `%LOCALAPPDATA%\Programs\mkscript\uninstall.cmd`.

## Install mkscript on Ubuntu and Debian

Use the stable alias so the command stays the same across releases:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.deb
sudo apt install ./mkscript.deb
```

Versioned package pattern:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/download/vX.Y.Z/mkscript_X.Y.Z-1_all.deb
sudo apt install ./mkscript_X.Y.Z-1_all.deb
```

## Install mkscript on Fedora

Use the stable alias:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo dnf install ./mkscript.rpm
```

Versioned package pattern:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/download/vX.Y.Z/mkscript-X.Y.Z-1.fc42.noarch.rpm
sudo dnf install ./mkscript-X.Y.Z-1.fc42.noarch.rpm
```

## Install mkscript on RHEL, Rocky Linux, and AlmaLinux

Use the stable alias:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.rpm
sudo yum install ./mkscript.rpm
```

Versioned package pattern:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/download/vX.Y.Z/mkscript-X.Y.Z-1.fc42.noarch.rpm
sudo yum install ./mkscript-X.Y.Z-1.fc42.noarch.rpm
```

## Download the mkscript source tarball

Stable alias:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/mkscript.tar.gz
```

Versioned source archive pattern:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/download/vX.Y.Z/mkscript-X.Y.Z.tar.gz
```

## Verify checksums

Download the current checksum file:

```bash
curl -LO https://github.com/seriousCoding/mkscript/releases/latest/download/SHA256SUMS
```

Verify a macOS download:

```bash
shasum -a 256 mkscript.tar.gz
```

Verify a Linux download:

```bash
sha256sum mkscript.deb
sha256sum mkscript.rpm
```

On Windows:

```powershell
Get-FileHash .\mkscript-windows-x64.zip -Algorithm SHA256
```

Current release documents:

- [Latest release page](https://github.com/seriousCoding/mkscript/releases/latest)
- [Current checksums](https://github.com/seriousCoding/mkscript/releases/latest/download/SHA256SUMS)

## After install

Show the version and help text:

```bash
mkscript --version
mkscript --help
```

Common examples:

```bash
mkscript demo
mkscript -s deploy
mkscript --template dockerfile Dockerfile
mkscript --template docker-compose compose.yaml
mkscript --template k8s-deployment deployment.yaml
mkscript demo -g
mkscript -c demo
mkscript -r demo
mkscript -f
mkscript -f 1
mkscript -f bash demo.sh
printf '%s\n' bash demo.sh | mkscript -f
```

## More documentation

- [https://seriouscoding.github.io/](https://seriouscoding.github.io/): public package overview page
- [`README.md`](README.md): project overview and usage
- [`docs/official-package-inclusion.md`](docs/official-package-inclusion.md): Debian, Ubuntu, Fedora, and EPEL inclusion path
