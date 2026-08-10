#!/usr/bin/env bash
set -euo pipefail

dist_dir=${1:-dist}

if [ ! -d "$dist_dir" ]; then
  printf 'Artifact directory not found: %s\n' "$dist_dir" >&2
  exit 64
fi

if command -v sha256sum >/dev/null 2>&1; then
  hash_command=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  hash_command=(shasum -a 256)
else
  printf 'Neither sha256sum nor shasum is available.\n' >&2
  exit 69
fi

artifact_count=0
output_file="$dist_dir/SHA256SUMS"
artifacts=()

shopt -s nullglob
for file in "$dist_dir"/*; do
  if [ "$(basename "$file")" = 'SHA256SUMS' ] || [ ! -f "$file" ]; then
    continue
  fi

  artifacts+=("$(basename "$file")")
done
shopt -u nullglob

artifact_count=${#artifacts[@]}

if [ "$artifact_count" -eq 0 ]; then
  printf 'No artifacts found in %s\n' "$dist_dir" >&2
  rm -f "$output_file"
  exit 65
fi

(
  cd "$dist_dir"
  for file in "${artifacts[@]}"; do
    "${hash_command[@]}" "$file"
  done
) > "$output_file"

printf 'Wrote checksums: %s\n' "$output_file"
