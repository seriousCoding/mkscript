#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

docker run --rm \
  -v "$repo_root:/workspace" \
  -w /workspace \
  fedora:42 \
  bash -lc '
    set -euo pipefail
    dnf -y install make rpm-build rpmdevtools rpmlint tar gzip glibc-langpack-en
    ./scripts/build-rpm-native.sh
  '
