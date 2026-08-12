#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

stage_dir=$(mktemp -d)
archive_root="$stage_dir/mkscript-$MKSCRIPT_VERSION"

cleanup() {
  rm -rf "$stage_dir"
}

trap cleanup EXIT

mkdir -p "$repo_root/dist" "$archive_root"

items=(
  .github
  .gitignore
  CHANGELOG.md
  INSTALL.md
  install.ps1
  LICENSE
  Makefile
  README.md
  VERSION
  debian
  docs
  mkscript.1
  packaging
  scripts
  src
  test
)

for item in "${items[@]}"; do
  cp -R "$repo_root/$item" "$archive_root/$item"
done

"$archive_root/scripts/sync-release-metadata.sh" "$archive_root"

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$archive_root"
fi

LC_ALL=C LANG=C COPYFILE_DISABLE=1 COPY_EXTENDED_ATTRIBUTES_DISABLE=1 \
  tar -C "$stage_dir" -czf "$repo_root/dist/$MKSCRIPT_SOURCE_ARCHIVE" "mkscript-$MKSCRIPT_VERSION"
printf 'Built source archive: %s\n' "$repo_root/dist/$MKSCRIPT_SOURCE_ARCHIVE"
