#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

rm -rf "$repo_root/build" "$repo_root/dist"
mkdir -p "$repo_root/dist"

"$repo_root/scripts/sync-release-metadata.sh"
"$repo_root/scripts/validate-release-metadata.sh"
make -C "$repo_root" test
make -C "$repo_root" lint
"$repo_root/scripts/build-source-archive.sh"
archive_sha=$(sha256_file "$repo_root/dist/$MKSCRIPT_SOURCE_ARCHIVE")
"$repo_root/scripts/render-homebrew-formula.sh" \
  "$MKSCRIPT_RELEASE_SOURCE_URL" \
  "$archive_sha" \
  "$repo_root/dist/mkscript.rb"
"$repo_root/scripts/build-deb-docker.sh"
"$repo_root/scripts/build-rpm-docker.sh"
"$repo_root/scripts/write-release-aliases.sh" "$repo_root/dist"
"$repo_root/scripts/write-checksums.sh" "$repo_root/dist"
