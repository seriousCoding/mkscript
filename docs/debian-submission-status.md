# Debian Submission Status for `mkscript`

Last updated: August 10, 2026

## Ready now

- Package name: `mkscript`
- Maintainer email in packaging: `rtownsend.appdesign.dev@gmail.com`
- Debian control metadata present
- Debian binary package builds cleanly
- Debian lint check passes with the Debian profile
- RPM package builds cleanly
- Test suite passes
- GitHub repository and release are public
- ITP draft prepared in `docs/debian-itp-mkscript.md`
- RFS draft prepared in `docs/debian-rfs-mkscript.md`

## External blockers

- `salsa.debian.org` account is pending administrator approval
- `mentors.debian.net` account still needs to be created and confirmed
- A GPG/OpenPGP key for `rtownsend.appdesign.dev@gmail.com` still needs to exist and be usable from the packaging environment

## Next steps once accounts are ready

1. Create a normal `mentors.debian.net` account.
2. Ensure the GPG public key is added to the Mentors control panel.
3. Build a signed Debian source package with `./scripts/build-deb-source.sh`.
4. Upload the signed source package to Mentors with `dput mentors ...changes`.
5. File the ITP bug using `docs/debian-itp-mkscript.md`.
6. File the RFS bug using `docs/debian-rfs-mkscript.md` after the Mentors upload exists.
7. After sponsorship and acceptance into Debian, watch Ubuntu sync windows for import into `universe`.
