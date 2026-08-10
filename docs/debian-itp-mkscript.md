# ITP Draft for `mkscript`

Subject: `ITP: mkscript -- create executable Bash script skeletons safely`

Package: `wnpp`
Severity: `wishlist`
Owner: `Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com>`

## Draft body

```text
* Package name    : mkscript
  Version         : 1.0.1
  Upstream Contact: Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com>
* URL             : https://github.com/seriousCoding/mkscript
* License         : MIT
  Programming Lang: shell
  Description     : create executable Bash script skeletons safely

 mkscript creates executable Bash script files with a standard
 #!/usr/bin/env bash shebang.
 .
 It refuses to overwrite existing files, symlinks, and directories,
 and can optionally add set -euo pipefail via -s or --strict.

This package is useful because it provides a small command-line tool for
creating Bash script stubs quickly and safely while following the familiar
strict-mode convention.

The package already includes:
 - automated tests
 - a manual page
 - Debian packaging
 - RPM packaging
 - CI automation

I intend to maintain this package under sponsorship.
```

## Filing notes

- File this against the `wnpp` pseudo-package.
- After filing, record the bug number and add `Closes: #BUGNUMBER` to the next Debian changelog entry when preparing the sponsor upload.
- Do not invent the bug number in advance.
