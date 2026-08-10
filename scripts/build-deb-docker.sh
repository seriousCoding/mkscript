#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

docker run --rm \
  -v "$repo_root:/workspace" \
  -w /workspace \
  debian:bookworm-slim \
  bash -lc '
    set -euo pipefail
    apt-get update
    apt-get install -y --no-install-recommends build-essential debhelper devscripts dpkg-dev fakeroot lintian make
    ./scripts/build-deb-native.sh
  '
