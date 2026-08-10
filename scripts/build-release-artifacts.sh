#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

rm -rf "$repo_root/build" "$repo_root/dist"
mkdir -p "$repo_root/dist"

make -C "$repo_root" test
"$repo_root/scripts/build-source-archive.sh"
"$repo_root/scripts/build-deb-docker.sh"
"$repo_root/scripts/build-rpm-docker.sh"
"$repo_root/scripts/write-release-aliases.sh" "$repo_root/dist"
"$repo_root/scripts/write-checksums.sh" "$repo_root/dist"
