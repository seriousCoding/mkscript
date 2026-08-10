# RFS Draft for `mkscript`

Subject: `RFS: mkscript/1.0.1-1 -- create executable Bash script skeletons safely`

Package: `sponsorship-requests`
Severity: `wishlist`
Owner: `Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com>`

## Draft body

```text
Package: sponsorship-requests
Severity: wishlist
X-Debbugs-CC: debian-mentors@lists.debian.org

Dear mentors,

I am looking for a sponsor for my package "mkscript":

 * Package name     : mkscript
   Version          : 1.0.1-1
   Upstream contact : Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com>
 * URL              : https://github.com/seriousCoding/mkscript
 * License          : MIT
 * Vcs              : https://github.com/seriousCoding/mkscript
 * Summary          : create executable Bash script skeletons safely

The source builds the following binary package:

  mkscript - create executable Bash script skeletons safely

The package provides a small shell-based utility that creates executable
Bash script files with a standard shebang, refuses unsafe overwrites,
can optionally add set -euo pipefail through -s or --strict, and can
create shortcuts in ~/.local/bin for new or existing local scripts.

The package has been tested with:

 - local functional tests
 - Debian package builds
 - RPM package builds
 - Debian install smoke tests
 - Fedora install smoke tests

The package is lintian-clean apart from the standard
initial-upload-closes-no-bugs warning that applies before the ITP bug
number is linked in the changelog.

The package is available on mentors.debian.net:

  dget -x TBD_AFTER_MENTORS_UPLOAD

Changes since the initial packaging:

 - add global shortcut support
 - add link-only shortcut support
 - accept supported flags in flexible order

Best regards,
Richard CodeJunky Townsend
```

## Filing notes

- Do not send this until the source package has been uploaded to `mentors.debian.net`.
- Replace `TBD_AFTER_MENTORS_UPLOAD` with the real `dget` URL from Mentors.
- If an ITP bug exists by then, mention it explicitly and update the Debian changelog entry to close it.
