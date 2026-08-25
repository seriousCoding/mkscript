# Template Defaults And Docker Compose Plan

## Objective

Allow every supported creation template to infer a standard output filename
when no path is supplied, normalize missing filename extensions, add `docker`
as an alias for the Dockerfile template, and make Docker Compose output include
a reusable network and named volume.

## Confirmed Current Behavior

- Unix and Windows require exactly one output path for creation.
- Unix does not add template-specific extensions to explicit paths.
- The Dockerfile template is named `dockerfile`; `docker` is not accepted.
- Docker Compose contains only a service and port mapping, with no network or
  named volume declarations.

## Filename Rules

When no filename is provided, use these default names:

| Template | Default name | Missing-extension rule for an explicit name |
| --- | --- | --- |
| `bash` | `script.sh` | append `.sh` |
| `cmd` (Windows) | `script.cmd` | append `.cmd` |
| `terraform` | `main.tf` | append `.tf` |
| `ansible` | `site.yml` | append `.yml` |
| `dockerfile` or `docker` | `Dockerfile` | none; Dockerfile has no extension |
| `docker-compose` | `docker-compose.yml` | append `.yml` |
| every `k8s-*` template | the suffix after `k8s-` plus `.yaml` | append `.yaml` |

For example, `mkscript -t docker` resolves to `Dockerfile`, and
`mkscript -t docker-compose` resolves to `docker-compose.yml`. An explicit
`mkscript -t terraform infrastructure` resolves to `infrastructure.tf`.

## Confirmation Rules

When `mkscript` infers a default filename because no filename was supplied, it
will ask for confirmation before creating the file. The prompt will state the
resolved default and show the alternative explicit form, for example:

```
No output filename was supplied. Create 'Dockerfile'? [y/N]
To provide a filename, use: mkscript -t docker Dockerfile
```

Declining leaves the filesystem unchanged. Explicit output paths continue to
create without this default-name confirmation.

## Docker Compose Output

The generated Compose template will retain a target-derived service name and
add:

- a named bridge network referenced by that service;
- a named volume mounted by that service;
- top-level `networks` and `volumes` declarations.

The network and volume names will be derived from the normalized service name,
so independent generated Compose files remain self-contained.

## Implementation Steps

1. Add shared template normalization and default-target resolution to the Unix
   implementation, including the `docker` alias and extension mappings above.
2. Implement the same resolution in the native Windows PowerShell
   implementation, retaining Windows `.cmd` behavior and applying the same
   non-script template filenames.
3. Add default-name confirmation only for omitted creation paths, including a
   copyable command that uses the selected template and inferred filename.
4. Update Unix and Windows Docker Compose templates with a service network,
   volume mount, and top-level named network/volume declarations.
5. Add Unix and Windows regression tests for each default name, extension
   normalization, `docker` alias, default-confirmation acceptance/cancellation,
   and Compose network/volume content.
6. Update help output, README, man page, and packaging-facing documentation to
   describe aliases, default names, extension handling, and confirmation.
7. Run full Unix tests, release-script tests, documentation checks, ShellCheck,
   release metadata validation, PowerShell parser checks, Windows CI, and the
   release workflow before publishing.

## Scope Boundaries

- No overwrite behavior changes: an inferred or extension-normalized path that
  already exists remains an error.
- No changes to move, global-link, wrapper, or file-lookup behavior.
- No Docker runtime installation or validation is added; generated Compose YAML
  is verified structurally by repository tests.

## Acceptance Criteria

- `mkscript -t docker` creates `Dockerfile` after confirmation.
- `mkscript -t docker-compose` creates `docker-compose.yml` after confirmation.
- Every template has a deterministic default filename and explicit extension
  normalization as specified above on its supported platforms.
- A declined default-name confirmation creates no file.
- `docker` and `dockerfile` generate equivalent Dockerfile content.
- Generated Compose files include a service-level network and volume reference
  plus top-level named `networks` and `volumes` declarations.
- Unix and Windows behavior are covered by tests and CI.
