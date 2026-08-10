#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)
dist_dir="$repo_root/dist"
build_root=$(mktemp -d)
package_root="$build_root/mkscript"

cleanup() {
  rm -rf "$build_root"
}

trap cleanup EXIT

mkdir -p "$dist_dir" "$package_root"
cp -R "$repo_root/." "$package_root"
rm -rf "$package_root/.git" "$package_root/build" "$package_root/dist" "$package_root/outputs" "$package_root/work"

cd "$package_root"
dpkg-buildpackage -us -uc -b
lintian \
  --profile debian \
  --fail-on error \
  --suppress-tags initial-upload-closes-no-bugs \
  ../*.changes
cp ../*.deb ../*.buildinfo ../*.changes "$dist_dir"/
printf 'Built Debian artifacts in %s\n' "$dist_dir"
