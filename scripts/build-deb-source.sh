#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

dist_dir="$repo_root/dist"
build_root=$(mktemp -d)
package_root="$build_root/mkscript"
orig_stage_root="$build_root/mkscript-$MKSCRIPT_VERSION"
orig_archive="$build_root/mkscript_${MKSCRIPT_VERSION}.orig.tar.gz"

cleanup() {
  rm -rf "$build_root"
}

trap cleanup EXIT

require_gpg() {
  if command -v gpg >/dev/null 2>&1 || command -v gpg2 >/dev/null 2>&1; then
    return 0
  fi

  printf 'gpg is required to build a signed Debian source package.\n' >&2
  printf 'Install gnupg or rerun with ALLOW_UNSIGNED=1 for a preflight build.\n' >&2
  return 1
}

mkdir -p "$dist_dir" "$package_root"
cp -R "$repo_root/." "$package_root"
rm -rf "$package_root/.git" "$package_root/build" "$package_root/dist" "$package_root/outputs" "$package_root/work"
"$package_root/scripts/sync-release-metadata.sh" "$package_root"

mkdir -p "$orig_stage_root"
for item in .github .gitignore CHANGELOG.md LICENSE Makefile README.md VERSION docs mkscript.1 packaging scripts src test; do
  cp -R "$repo_root/$item" "$orig_stage_root/$item"
done
"$orig_stage_root/scripts/sync-release-metadata.sh" "$orig_stage_root"
tar -C "$build_root" -czf "$orig_archive" "mkscript-$MKSCRIPT_VERSION"

cd "$package_root"

sign_args=()
if [[ "${ALLOW_UNSIGNED:-0}" == "1" ]]; then
  sign_args=(-us -uc)
else
  require_gpg
fi

dpkg-buildpackage "${sign_args[@]}" -S -sa
lintian \
  --profile debian \
  --fail-on error \
  --suppress-tags initial-upload-closes-no-bugs \
  ../*.changes
cp ../*.dsc ../*.debian.tar.xz ../*.orig.tar.* ../*.buildinfo ../*.changes "$dist_dir"/
printf 'Built Debian source artifacts in %s\n' "$dist_dir"
