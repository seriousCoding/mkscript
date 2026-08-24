# Windows Release Fix Plan

## Objective

Repair the PowerShell parsing error that stops the `v1.5.0` Windows package job,
then publish a verified release containing the Windows, Linux, and macOS updates.

## Confirmed Failure

The `windows-package` GitHub Actions job for `v1.5.0` fails before test execution.
In `src/mkscript.ps1.in`, the Docker Compose template interpolates
`$serviceName:`. PowerShell interprets the colon as part of the variable
reference and reports `InvalidVariableReferenceWithDrive`.

## Implementation Steps

1. Update only the Docker Compose template interpolation so PowerShell explicitly
   delimits `serviceName` before the YAML colon, while preserving the generated
   Compose service name and all other template output.
2. Strengthen the Windows test case for `docker-compose` to verify the generated
   service key, not only the top-level `services:` field. This prevents a parser
   fix that produces incomplete output from passing.
3. Run the Windows PowerShell parser check and Windows test suite locally when
   PowerShell is available. If it is unavailable on this host, record that limit
   and rely on GitHub's `windows-latest` CI run for execution verification.
4. Run the complete cross-platform repository test suite, release metadata
   validation, and whitespace validation.
5. Commit and push the fix to `main`, create a corrected release tag only after
   all local checks pass, then verify the GitHub workflow publishes the Windows
   ZIP and the Debian/RPM/macOS release artifacts and that `releases/latest`
   resolves to the corrected version.

## Scope Boundaries

- No changes to Linux/macOS script behavior.
- No changes to the documented Windows restriction on `--template bash`.
- No package-manager metadata changes unless validation identifies a direct
  release-blocking defect.

## Acceptance Criteria

- `src/mkscript.ps1.in` parses on Windows PowerShell.
- `mkscript --template docker-compose compose.yaml` creates YAML with a valid
  `services:` section and the normalized target filename as its service name.
- Windows CI completes the `windows-package` job and uploads its artifact.
- Release publishing completes, assets include the Windows package and existing
  Linux/macOS deliverables, and GitHub marks the new version as `latest`.
