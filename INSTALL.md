# Install mkscript

`mkscript` creates executable Bash script skeletons and optional user-bin shortcuts on macOS and Linux.

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

If you plan to use `-g` or `-l`, make sure your chosen personal bin directory is on `PATH`. `mkscript` prefers `~/.local/bin`, `~/bin`, or another personal `*local*/bin` directory already present on `PATH`.

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
mkscript demo -g
mkscript -c demo
mkscript -r demo
```

## More documentation

- [https://seriouscoding.github.io/](https://seriouscoding.github.io/): public package overview page
- [`README.md`](README.md): project overview and usage
- [`docs/official-package-inclusion.md`](docs/official-package-inclusion.md): Debian, Ubuntu, Fedora, and EPEL inclusion path
