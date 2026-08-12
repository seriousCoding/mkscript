# Windows package publishing

The Windows release job builds these assets:

- `mkscript-<version>-windows-x64.zip` and the stable `mkscript-windows-x64.zip` alias
- `mkscript.<version>.nupkg` for Chocolatey
- a checksum-pinned WinGet three-file manifest set

## First public release

1. Publish the GitHub release so its versioned ZIP URL exists.
2. Submit `dist/winget/seriousCoding.mkscript.yaml` to `microsoft/winget-pkgs`. After the first manifest is accepted, later tagged releases can use WingetCreate automation.
3. Create/claim the `mkscript` package on Chocolatey Community and push the generated `.nupkg` for moderation.

## WinGet first-contributor checklist

- [x] Search for an existing manifest and open PR for `seriousCoding.mkscript` version `1.5.0`.
- [x] Keep the submission to one package identifier and one version.
- [x] Keep the winget-pkgs PR to manifest files only.
- [x] Use a supported ZIP/portable executable that runs without interaction.
- [x] Use the required three-file manifest set; singleton manifests are not accepted.
- [x] Put a schema header on every manifest and use schema `1.12.0`.
- [x] Use the publisher-owned, version-specific GitHub release URL and its SHA-256.
- [ ] Publish `v1.5.0` and its Windows ZIP so the manifest URL becomes downloadable.
- [ ] Run `winget validate --manifest <manifest-directory>` or WingetCreate validation.
- [ ] Enable local manifests and run `winget install --manifest <manifest-directory>`.
- [ ] If available, run `Tools/SandboxTest.ps1` in Windows Sandbox.
- [ ] Submit the manifest-only PR, complete the Microsoft CLA if prompted, and monitor validation labels.

The unchecked validation/install steps cannot pass before the version-specific release asset exists. WingetCreate also needs its per-user local state directory and GitHub authentication when it submits the first manifest.

## Repository secrets

- `CHOCOLATEY_API_KEY`: enables `choco push` after a tagged GitHub release.
- `WINGET_CREATE_GITHUB_TOKEN`: enables `wingetcreate update ... --submit` after the initial WinGet package has been accepted. The token needs access to create the winget-pkgs submission fork and pull request.

If a secret is absent, the corresponding publish job exits successfully and leaves the built package/manifest available as workflow artifacts for manual submission.

## Local generation

```powershell
./scripts/build-windows-package.ps1
./scripts/build-windows-package-managers.ps1
```

Use `-SkipChocolateyPack` on the second command when Chocolatey CLI is unavailable; the rendered Chocolatey source and WinGet manifest are still produced.
