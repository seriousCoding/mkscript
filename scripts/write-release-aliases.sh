#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)
dist_dir=${1:-"$repo_root/dist"}
version=$(cat "$repo_root/VERSION")

if [ ! -d "$dist_dir" ]; then
  printf 'Artifact directory not found: %s\n' "$dist_dir" >&2
  exit 64
fi

shopt -s nullglob

find_single_artifact() {
  local description=$1
  shift
  local matches=("$@")

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

source_archive=$(find_single_artifact 'source archive' "$dist_dir"/mkscript-"$version".tar.gz)
deb_package=$(find_single_artifact 'Debian package' "$dist_dir"/mkscript_"$version"-*_all.deb)
binary_rpm=$(find_single_artifact 'binary RPM package' "$dist_dir"/mkscript-"$version"-*.noarch.rpm)
source_rpm=$(find_single_artifact 'source RPM package' "$dist_dir"/mkscript-"$version"-*.src.rpm)

copy_alias "$source_archive" "$dist_dir/mkscript.tar.gz"
copy_alias "$deb_package" "$dist_dir/mkscript.deb"
copy_alias "$binary_rpm" "$dist_dir/mkscript.rpm"
copy_alias "$source_rpm" "$dist_dir/mkscript.src.rpm"

shopt -u nullglob
