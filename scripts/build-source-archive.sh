#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)
version=$(cat "$repo_root/VERSION")
archive_name="mkscript-$version.tar.gz"
stage_dir=$(mktemp -d)
archive_root="$stage_dir/mkscript-$version"

cleanup() {
  rm -rf "$stage_dir"
}

trap cleanup EXIT

mkdir -p "$repo_root/dist" "$archive_root"

items=(
  .github
  .gitignore
  CHANGELOG.md
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

tar -C "$stage_dir" -czf "$repo_root/dist/$archive_name" "mkscript-$version"
printf 'Built source archive: %s\n' "$repo_root/dist/$archive_name"
