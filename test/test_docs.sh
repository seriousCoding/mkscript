#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file_contains() {
  local file=$1
  local needle=$2
  local message=$3

  if ! grep -Fq -- "$needle" "$file"; then
    fail "$message"
  fi
}

readme_lookup_columns="\`QUERY\`, \`FOUND\`, \`TYPE\`, \`LOCATION\`, and \`DIRECTORY\`."
readme_quote_note="Quote glob patterns so your shell passes them to \`mkscript\` unchanged."

assert_file_contains "$repo_root/README.md" "mkscript -f 'install-wifi*'" 'README should document quoted glob lookup examples'
assert_file_contains "$repo_root/README.md" "$readme_quote_note" 'README should explain why glob queries must be quoted'
assert_file_contains "$repo_root/README.md" "$readme_lookup_columns" 'README should document the full lookup output columns'
assert_file_contains "$repo_root/README.md" 'mkscript --template dockerfile Dockerfile' 'README should include a Dockerfile template example'
assert_file_contains "$repo_root/README.md" 'mkscript --template k8s-deployment deployment.yaml' 'README should include a Kubernetes template example'
assert_file_contains "$repo_root/README.md" 'It does not support `--template bash`.' 'README should document the Windows bash-template restriction'
assert_file_contains "$repo_root/INSTALL.md" 'mkscript --template docker-compose compose.yaml' 'INSTALL should include a Docker Compose example'
assert_file_contains "$repo_root/INSTALL.md" 'mkscript --template k8s-deployment deployment.yaml' 'INSTALL should include a Kubernetes example'
assert_file_contains "$repo_root/mkscript.1" 'quoted shell-style glob patterns such as' 'man page should introduce quoted glob lookup'
assert_file_contains "$repo_root/mkscript.1" "install-wifi*" 'man page should include the glob pattern example text'
assert_file_contains "$repo_root/mkscript.1" "mkscript -f 'install-wifi*'" 'man page should include a quoted glob lookup example'
assert_file_contains "$repo_root/mkscript.1" 'mkscript --template dockerfile Dockerfile' 'man page should include a Dockerfile template example'
assert_file_contains "$repo_root/mkscript.1" 'mkscript --template k8s-deployment deployment.yaml' 'man page should include a Kubernetes template example'

printf 'Documentation checks passed.\n'
