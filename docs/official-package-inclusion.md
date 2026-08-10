# Official Packaging Path: Debian, Ubuntu, Fedora, and EPEL

Verified against current project documentation on Monday, August 10, 2026.

## Recommended order

For a small CLI like `mkscript`, the lowest-friction path is usually:

1. Land it in Debian first.
2. Let Ubuntu sync it automatically when timing allows.
3. Package it in Fedora.
4. Branch it into EPEL for RHEL-compatible systems.

That order minimizes duplicate packaging work because Ubuntu explicitly syncs many new packages from Debian `unstable`, and EPEL follows the Fedora packaging ecosystem.

## Debian

### What Debian expects

- A package bug in WNPP, usually an `ITP` for a brand new package.
- Policy-compliant packaging in `debian/`.
- Clean licensing and copyright metadata.
- Successful builds and linting.
- A sponsor if you are not already a Debian Developer or Debian Maintainer with the needed upload rights.
- First-time uploads to the archive to pass the NEW queue review.

### Accounts and prerequisites

- Debian bug tracker access and `reportbug`.
- A public VCS location for review. GitHub works for upstream; a Salsa mirror is strongly preferred in Debian workflows.
- `devscripts`, `debhelper`, `dpkg-dev`, `lintian`, and a clean build tool such as `sbuild` or `pbuilder`.
- A GPG key is practically required for long-term Debian packaging work, especially once you move beyond sponsor-mediated uploads.

### Core file structure

Expected files for a package like this:

- `debian/control`
- `debian/changelog`
- `debian/copyright`
- `debian/rules`
- `debian/source/format`
- `debian/watch`
- `debian/tests/control`

For `mkscript`, these files already exist in this repository.

### Step-by-step path

1. File the WNPP bug.

```bash
reportbug wnpp
```

Use `ITP: mkscript -- create executable Bash script skeletons safely`.

2. Build the source package and binary package locally.

```bash
debuild -S -sa
debuild -us -uc -b
```

3. Lint and test it.

```bash
lintian ../mkscript_1.0.0-1_all.changes
autopkgtest . -- null
```

For real review work, also do clean-room builds with `sbuild` or `pbuilder`.

4. Ask for sponsorship.

- Post the repo link, WNPP bug number, and build results.
- Ask on `debian-mentors` or in the relevant Debian team if there is a natural team home.

5. Sponsor uploads the package.

- First-time uploads enter the NEW queue.
- Expect review of namespace, policy compliance, and license/copyright accuracy.

6. Respond to NEW feedback quickly and precisely.

- Fix metadata gaps.
- Clarify copyright and source availability.
- Update the package and re-request sponsorship if needed.

### Debian commands worth knowing

```bash
reportbug wnpp
debuild -S -sa
debuild -us -uc -b
lintian ../mkscript_1.0.0-1_all.changes
autopkgtest . -- null
```

### Debian maintenance obligations

- Keep `debian/changelog` current.
- Track Debian Policy changes before bumping `Standards-Version`.
- Respond to bugs, RC bugs, and QA feedback.
- Keep watch files and upstream releases current.
- Handle security fixes promptly.
- Maintain license accuracy if upstream files change.

## Ubuntu

### The normal path from Debian to Ubuntu

Ubuntu documentation is explicit: new packages in Debian `unstable` are automatically synced into Ubuntu before Debian Import Freeze. For a package like `mkscript`, that is the preferred route when possible.

### When Debian-first is enough

If all of the following are true:

- `mkscript` is accepted into Debian `unstable`
- it is before Debian Import Freeze for the active Ubuntu development release
- Ubuntu does not need a distro-specific delta

then Ubuntu usually imports it automatically.

### When you need a separate Ubuntu process

You need extra Ubuntu work if:

- the package misses Debian Import Freeze
- the package is not in Debian at all
- Ubuntu needs changes that Debian does not carry
- you want it in `main` or `restricted`, not just `universe`

### Accounts and prerequisites

- Launchpad account
- Ubuntu development tooling such as `ubuntu-dev-tools`
- PPA access for pre-review builds
- Sponsor relationship if you do not have Ubuntu upload rights

### Common Ubuntu paths

#### New package request

If the package is not already flowing from Debian, file a Launchpad bug and add `needs-packaging`.

#### Manual sync after Debian Import Freeze

If the package is already in Debian but missed the automatic sync window:

```bash
requestsync mkscript
```

Or, if you have the required upload permissions:

```bash
syncpackage --release=<ubuntu-release> --distribution=unstable --verbose --force mkscript
```

#### Ubuntu-specific upload

If Ubuntu needs its own delta, build and test in a PPA first, then request sponsorship for the Ubuntu upload.

### Main Inclusion Review

If `mkscript` is ever intended for `main` or `restricted`, a Main Inclusion Review is required. That review checks long-term maintainability, security/support burden, and dependency placement.

### Ubuntu commands worth knowing

```bash
requestsync mkscript
syncpackage --release=<ubuntu-release> --distribution=unstable --verbose --force mkscript
```

### Ubuntu maintenance obligations

- Keep Ubuntu delta as small as possible.
- Push Ubuntu fixes back to Debian whenever possible.
- Watch freeze dates closely.
- Maintain autopkgtests and PPA validation.
- Be ready for sponsorship review comments or MIR follow-up if targeting `main`.

## Fedora

### What Fedora expects

- A Fedora Account System account.
- Acceptance of the Fedora Project Contributor Agreement.
- A spec file and source tarball that comply with Fedora packaging guidelines.
- A review bug for new packages.
- Sponsorship into the `packager` group for new contributors.

### Accounts and prerequisites

- Fedora account
- FPCA signed digitally in FAS
- Bugzilla account tied to the same email identity you use for review work
- Tooling such as `fedpkg`, `mock`, `rpmlint`, `fedora-review`, and `koji`

### Core file structure

For `mkscript`, the Fedora package is centered on:

- `packaging/rpm/mkscript.spec`
- `mkscript-<version>.tar.gz`

You should also expect `%check` coverage and clean `rpmlint` output.

### Step-by-step path

1. Build the SRPM and test locally.

```bash
./scripts/build-source-archive.sh
rpmbuild -ba packaging/rpm/mkscript.spec
rpmlint packaging/rpm/mkscript.spec
```

2. Run a clean build in `mock`.

```bash
mock -r fedora-rawhide-x86_64 --rebuild mkscript-1.0.0-1.src.rpm
```

3. File the review bug in Fedora Bugzilla.

- Attach or link the SRPM.
- Link the upstream repo and spec.

4. Work through package review comments.

- Licensing
- macro usage
- source URL correctness
- scriptlets and file ownership
- test coverage

5. Get sponsored into the `packager` group if you are new.

6. Request the dist-git repo and Rawhide branch, then build in Koji.

Typical commands after approval:

```bash
fedpkg request-repo --bugzilla <review-bug> mkscript
fedpkg clone mkscript
fedpkg build
```

### Fedora maintenance obligations

- Keep the spec current.
- Maintain `%check` as upstream changes.
- Handle review follow-ups, FTBFS bugs, and mass rebuild fallout.
- Build updates in Koji and push updates through Bodhi.
- Watch license changes carefully because Fedora packaging review is strict here.

## EPEL

### Best path

The cleanest route is usually:

1. Get `mkscript` accepted in Fedora first.
2. Request EPEL branches for the supported Enterprise Linux versions you want.

### What EPEL documentation highlights

- EPEL uses the Fedora packager ecosystem.
- If the package is not yet present in the target EPEL branch, request the branch.
- EPEL package requests can come from end users or maintainers, but maintainers still need to package and build it.

### Typical EPEL flow

```bash
fedpkg request-branch epel9
fedpkg switch-branch epel9
fedpkg build
```

For Fedora-compatible future branches:

```bash
fedpkg request-branch epel10
```

If ABI timing requires it, you may also encounter `epel9-next`.

### Maintenance obligations in EPEL

- Keep compatibility with the matching RHEL major version.
- Avoid pulling in dependencies that are unavailable in the target Enterprise Linux base.
- Be conservative with updates compared with fast-moving Fedora branches.
- Watch EPEL policy and branch lifecycle changes over time.

## Testing and linting checklist before asking any distro to review the package

### Debian and Ubuntu

```bash
make test
lintian ../mkscript_1.0.0-1_all.changes
autopkgtest . -- null
```

### Fedora and EPEL

```bash
make test
rpmlint packaging/rpm/mkscript.spec
mock -r fedora-rawhide-x86_64 --rebuild mkscript-1.0.0-1.src.rpm
```

## Licensing checklist

- Use a license already accepted by the target distro. MIT is fine for all four paths here.
- Ensure the upstream `LICENSE` file matches the package metadata exactly.
- Keep Debian `debian/copyright` accurate and machine-readable.
- Keep Fedora `License:` in the spec aligned with Fedora license naming expectations.
- Verify that all shipped documentation and generated assets are redistributable.

## Expected costs and fees

I found no official submission fee in the current Debian, Ubuntu, Fedora, or EPEL documentation reviewed for this project.

Practical costs are usually optional and external:

- hardware or VM capacity for clean builds
- time for reviewer feedback cycles
- optional OpenPGP hardware token
- optional hosted CI minutes if you outgrow free tiers

That "no official fee" statement is an inference from the current documentation and process pages rather than a single explicit fee policy page.

## Suggested real-world strategy for `mkscript`

1. Keep upstream releases small, well-documented, and tagged.
2. Submit to Debian first with the packaging already present in this repository.
3. Once accepted into Debian `unstable`, watch the Ubuntu cycle and let it sync automatically when timing allows.
4. In parallel, submit the Fedora review request using the spec already present here.
5. After Fedora acceptance, request `epel9` and later branches as needed.

## References

- Debian Policy Manual: <https://www.debian.org/doc/debian-policy/>
- Debian Policy upgrading checklist: <https://www.debian.org/doc/debian-policy/upgrading-checklist.html>
- Debian Developers Reference, sponsorship section: <https://www.debian.org/doc/manuals/developers-reference/developers-reference.en.html>
- Debian WNPP examples and process: <https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=wnpp>
- Debian NEW queue: <https://ftp-master.debian.org/new.html>
- Ubuntu new packages process: <https://ubuntu.com/project/docs/how-ubuntu-is-made/processes/new-packages/>
- Ubuntu merges and syncs: <https://ubuntu.com/project/docs/how-ubuntu-is-made/processes/merges-and-syncs/>
- Ubuntu request-a-sync guide: <https://ubuntu.com/project/docs/contributors/uploading/request-a-sync/>
- Ubuntu Main Inclusion Review: <https://ubuntu.com/project/docs/MIR/main-inclusion-review/>
- Fedora package review process: <https://docs.fedoraproject.org/en-US/package-maintainers/Package_Review_Process/>
- Fedora sponsorship path: <https://docs.fedoraproject.org/en-US/package-maintainers/How_to_Get_Sponsored_into_the_Packager_Group/>
- Fedora joining package maintainers: <https://docs.fedoraproject.org/en-US/package-maintainers/Joining_the_Package_Maintainers/>
- Fedora FPCA: <https://docs.fedoraproject.org/en-US/legal/fpca/>
- EPEL package requests: <https://docs.fedoraproject.org/en-US/epel/epel-package-request/>
- EPEL branches: <https://docs.fedoraproject.org/en-US/epel/branches/>
- EPEL FAQ: <https://docs.fedoraproject.org/en-US/epel/epel-faq/>
