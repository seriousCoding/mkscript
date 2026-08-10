#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

rm -rf "$repo_root/build" "$repo_root/dist"
mkdir -p "$repo_root/dist"

make -C "$repo_root" test
"$repo_root/scripts/build-source-archive.sh"
"$repo_root/scripts/render-homebrew-formula.sh" \
  "https://github.com/seriousCoding/mkscript/releases/download/v$(cat "$repo_root/VERSION")/mkscript-$(cat "$repo_root/VERSION").tar.gz" \
  "$(
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$repo_root/dist/mkscript-$(cat "$repo_root/VERSION").tar.gz" | awk '{print $1}'
    else
      shasum -a 256 "$repo_root/dist/mkscript-$(cat "$repo_root/VERSION").tar.gz" | awk '{print $1}'
    fi
  )" \
  "$repo_root/dist/mkscript.rb"
"$repo_root/scripts/build-deb-docker.sh"
"$repo_root/scripts/build-rpm-docker.sh"
"$repo_root/scripts/write-release-aliases.sh" "$repo_root/dist"
"$repo_root/scripts/write-checksums.sh" "$repo_root/dist"
