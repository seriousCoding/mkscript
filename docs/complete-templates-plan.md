# Complete Templates, Defaults, Helm, And Documentation Plan

## Objective

Make every `mkscript` creation template useful as a complete, editable
starting point. Add deterministic default names and extension handling,
provide a complete Helm chart directory template, expand Docker Compose with
networks and volumes, and make `--help` and the man page explain every flag
and supported template clearly on Unix and Windows.

## Confirmed Current Behavior

- Unix and Windows require a creation path.
- Unix does not add template-specific extensions. Windows adds `.cmd` only for
  command scripts.
- `dockerfile` exists, but `docker` is not an alias.
- Docker Compose has only a service and port mapping.
- Kubernetes templates are valid minimal manifests, but several omit common
  operational sections.
- Helm is not a supported template and no code generates directories.
- Existing help and man pages list flags, but do not consistently state legal
  combinations, platform behavior, defaults, prompts, or examples.

## Template Names And Targets

`docker` becomes an alias for `dockerfile` on every platform. These target
rules apply only to creation mode:

| Template | Default target when omitted | Explicit target without extension |
| --- | --- | --- |
| `bash` (Unix) | `script.sh` | append `.sh` when explicitly selected; preserve the legacy default `mkscript NAME` filename |
| `cmd` (Windows) | `script.cmd` | append `.cmd` |
| `terraform` | `main.tf` | append `.tf` |
| `ansible` | `site.yml` | append `.yml` |
| `dockerfile`, `docker` | `Dockerfile` | unchanged |
| `docker-compose` | `docker-compose.yml` | append `.yml` |
| every `k8s-*` template | its suffix plus `.yaml` | append `.yaml` |
| `helm` | `chart` directory | unchanged directory name |

An explicit filename with any extension is retained unchanged. For example,
`mkscript -t terraform infra` creates `infra.tf`, while
`mkscript -t terraform infra.hcl` retains `infra.hcl`.

## Omitted-Target Confirmation

When the creation target is omitted, `mkscript` resolves its default target and
requires confirmation before writing. It will also print the explicit command
form, preserving the user-selected alias:

```text
No output filename was supplied. Create 'Dockerfile'? [y/N]
To provide a filename, use: mkscript -t docker Dockerfile
```

For Helm, the wording identifies the target as a chart directory. A declined
prompt creates no file or directory. Explicit target paths remain
non-interactive. Existing-path refusal remains unchanged.

## Complete Template Content

All generated files retain the existing metadata header, target-derived safe
resource names, and valid syntax. They will contain complete, commented,
editable sections rather than placeholder-only empty maps or lists. Templates
will use repository-supported, pinned public images where a runnable container
is needed; users can replace them for their application.

### Scripts And Automation

- Bash: shebang, metadata, optional strict mode, argument/usage skeleton,
  reusable logging and error helpers, and a `main` function invocation.
- Windows CMD: `@echo off`, metadata, `setlocal`, argument/usage skeleton,
  error-level handling, labelled usage/main sections, and clean `endlocal`
  exit behavior. `--strict` retains its documented delayed-expansion behavior.
- Terraform: `terraform` requirements, `required_providers`, configurable
  input variables, locals, output, and comments identifying provider-specific
  resources as user-selected rather than hard-coded infrastructure.
- Ansible: a complete play with variables, `pre_tasks`, `tasks`, `handlers`,
  and `post_tasks`, including safe example task structure instead of an empty
  task list.

### Container Templates

- Dockerfile: pinned base image, non-root application user, work directory,
  dependency/copy layers, exposed application port, health check, and command
  section with comments showing what application-specific values to replace.
- Docker Compose: target-derived service name, image/build choice documented in
  comments, ports, environment block, health check, restart policy, resource
  limits, named volume mount, named bridge network, and top-level `volumes`
  and `networks` declarations. Network and volume names derive from the safe
  service name so each generated file is self-contained.

### Kubernetes Templates

Every supported `k8s-*` manifest will remain independently valid and include
the applicable common operational sections:

- metadata labels and annotations;
- selectors that match pod-template labels;
- configurable image, pull policy, environment variables, ports, resources,
  security context, and health probes for workload resources;
- complete service, ingress, storage, RBAC, autoscaling, and network-policy
  fields appropriate to that resource type;
- comments only where a cluster-specific value cannot be universally valid
  (such as an ingress class, storage provisioner, host path, or secret value).

The exact supported resource names remain: `namespace`, `pod`, `deployment`,
`service`, `configmap`, `secret`, `ingress`, `networkpolicy`, `serviceaccount`,
`role`, `rolebinding`, `clusterrole`, `clusterrolebinding`,
`persistentvolume`, `persistentvolumeclaim`, `storageclass`, `statefulset`,
`daemonset`, `job`, `cronjob`, and `horizontalpodautoscaler`.

### Helm Template

`mkscript -t helm NAME` will create a complete Helm chart directory named
`NAME`; it is the only directory-producing creation template. It will refuse
to overwrite an existing chart directory and will create parent directories
only when the supplied parent exists, matching current file-parent behavior.

The chart contains this standard structure:

```text
NAME/
  Chart.yaml
  values.yaml
  .helmignore
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    ingress.yaml
    serviceaccount.yaml
    configmap.yaml
    secret.yaml
    hpa.yaml
    networkpolicy.yaml
    persistentvolumeclaim.yaml
    NOTES.txt
    tests/test-connection.yaml
```

`values.yaml` exposes the image, replica count, service, ingress, resources,
autoscaling, service account, pod/container security contexts, persistence,
network policy, configuration, secret references, node scheduling, and common
labels. Templates use Helm conditionals so optional resources render only when
enabled. `helm lint` and `helm template` will validate the generated chart.

## Help And Man Page

Both Unix and Windows `--help` will provide:

- separate creation, global-link/wrapper, check, remove, move, and file lookup
  usage forms;
- each flag's purpose, accepted arguments, allowed templates/platforms, and
  invalid combinations;
- default target names, extension rules, omitted-target confirmation, and the
  `docker` alias;
- a compact template catalogue describing what each template produces,
  including the Helm directory structure;
- copyable examples for every mode, including `-mv -g` directory moves and
  template creation with and without an explicit name.

`mkscript.1`, `README.md`, and `INSTALL.md` will match the executable help,
including Windows-specific wrapper behavior and Unix-specific Bash global
links. No documentation will claim Bash template support on Windows.

## Implementation Steps

1. Add shared template normalization, aliases, default target resolution,
   missing-extension handling, and omitted-target confirmation to Unix Bash.
2. Implement equivalent creation behavior in native Windows PowerShell,
   retaining CMD-only global wrapper behavior and rejecting Bash on Windows.
3. Change the Unix and Windows writers so each existing template produces the
   complete content specified above without changing move/check/remove/files
   semantics.
4. Add the `helm` directory writer, path validation, overwrite safeguards, and
   standard chart files to Unix and Windows implementations.
5. Expand Unix and Windows help output and update the man page, README,
   INSTALL guide, package descriptions, and usage examples.
6. Add regression tests for target defaults, extensions, aliases, confirmation
   acceptance/refusal, all template content, Helm chart files, and illegal
   flag/template combinations on Unix and Windows.
7. Validate generated YAML and Helm charts where the CI environment provides
   the relevant tools; otherwise test exact files and syntax structurally.
8. Run `make test`, `make lint`, documentation and release metadata checks,
   PowerShell parser checks, GitHub Linux/macOS/Windows CI, then publish only
   after all workflows pass.

## Scope Boundaries

- No changes to `-mv`, `-g`, `-c`, `-r`, or `-f` semantics except clearer
  documentation.
- Existing explicit output paths stay non-interactive and are never silently
  overwritten.
- Helm generation creates a chart; it does not install Helm releases, require
  cluster credentials, or modify a Kubernetes cluster.
- Generated configuration contains documented values that users can edit; no
  external account, registry, cluster, provider, or secret is assumed.

## Acceptance Criteria

- Every supported template has a deterministic default target and extension
  behavior on its supported operating systems.
- `mkscript -t docker` and `mkscript -t dockerfile` create equivalent
  Dockerfiles; `mkscript -t docker-compose` creates `docker-compose.yml`.
- Omitted targets always display a copyable explicit alternative and require
  confirmation; refusal leaves no output behind.
- Every generated template contains valid, editable, non-empty operational
  sections appropriate to its type.
- Docker Compose includes a service network, volume mount, and top-level named
  network and volume.
- `mkscript -t helm NAME` creates the complete chart structure above, and the
  generated chart passes `helm lint` and `helm template` when Helm is
  available.
- Help, man page, README, and INSTALL documentation accurately describe all
  flags, defaults, examples, templates, and platform differences.
- Unix and actual GitHub Windows CI pass before release.
