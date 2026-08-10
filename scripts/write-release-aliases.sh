#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

dist_dir=${1:-"$repo_root/dist"}

if [ ! -d "$dist_dir" ]; then
  printf 'Artifact directory not found: %s\n' "$dist_dir" >&2
  exit 64
fi

shopt -s nullglob

find_single_artifact() {
  local description=$1
  local pattern=$2
  local matches=()

  while IFS= read -r match; do
    matches+=("$match")
  done < <(find "$dist_dir" -maxdepth 1 -type f -name "$pattern" -print | sort)

  if [ "${#matches[@]}" -ne 1 ]; then
    printf 'Expected exactly one %s artifact, found %s\n' "$description" "${#matches[@]}" >&2
    exit 65
  fi

  printf '%s\n' "${matches[0]}"
}

copy_alias() {
  local source_path=$1
  local alias_path=$2

  cp -f "$source_path" "$alias_path"
  printf 'Created release alias: %s -> %s\n' "$(basename "$alias_path")" "$(basename "$source_path")"
}

source_archive=$(find_single_artifact 'source archive' "$MKSCRIPT_SOURCE_ARCHIVE")
deb_package=$(find_single_artifact 'Debian package' "$MKSCRIPT_DEB_PACKAGE")
binary_rpm=$(find_single_artifact 'binary RPM package' "mkscript-${MKSCRIPT_VERSION}-*.noarch.rpm")
source_rpm=$(find_single_artifact 'source RPM package' "mkscript-${MKSCRIPT_VERSION}-*.src.rpm")

copy_alias "$source_archive" "$dist_dir/mkscript.tar.gz"
copy_alias "$deb_package" "$dist_dir/mkscript.deb"
copy_alias "$binary_rpm" "$dist_dir/mkscript.rpm"
copy_alias "$source_rpm" "$dist_dir/mkscript.src.rpm"

shopt -u nullglob
