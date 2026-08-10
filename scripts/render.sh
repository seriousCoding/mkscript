#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s TEMPLATE OUTPUT\n' "$(basename "$0")" >&2
  exit 64
fi

template=$1
output=$2
version=${VERSION:-}

if [ -z "$version" ]; then
  printf 'VERSION environment variable is required.\n' >&2
  exit 64
fi

case $output in
  */*)
    output_dir=${output%/*}
    if [ -z "$output_dir" ]; then
      output_dir=/
    fi
    ;;
  *)
    output_dir=.
    ;;
esac

mkdir -p "$output_dir"
sed "s/@VERSION@/$version/g" "$template" > "$output"
