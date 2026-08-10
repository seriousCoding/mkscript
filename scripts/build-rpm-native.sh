#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)
dist_dir="$repo_root/dist"
version=$(cat "$repo_root/VERSION")
archive_path="$dist_dir/mkscript-$version.tar.gz"
topdir=$(mktemp -d)

cleanup() {
  rm -rf "$topdir"
}

trap cleanup EXIT

if [ ! -f "$archive_path" ]; then
  "$repo_root/scripts/build-source-archive.sh"
fi

mkdir -p "$dist_dir" \
  "$topdir/BUILD" \
  "$topdir/BUILDROOT" \
  "$topdir/RPMS" \
  "$topdir/SOURCES" \
  "$topdir/SPECS" \
  "$topdir/SRPMS"

cp "$archive_path" "$topdir/SOURCES/"
cp "$repo_root/packaging/rpm/mkscript.spec" "$topdir/SPECS/"

rpmbuild --nodeps --define "_topdir $topdir" -ba "$topdir/SPECS/mkscript.spec"
LC_ALL=C LANG=C rpmlint "$topdir/SPECS/mkscript.spec" "$topdir/SRPMS/"*.src.rpm "$topdir/RPMS/noarch/"*.rpm
cp "$topdir/RPMS/noarch/"*.rpm "$topdir/SRPMS/"*.src.rpm "$dist_dir"/
printf 'Built RPM artifacts in %s\n' "$dist_dir"
