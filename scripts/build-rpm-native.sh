#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

dist_dir="$repo_root/dist"
archive_path="$dist_dir/$MKSCRIPT_SOURCE_ARCHIVE"
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

"$repo_root/scripts/sync-release-metadata.sh"
cp "$archive_path" "$topdir/SOURCES/"
cp "$repo_root/packaging/rpm/mkscript.spec" "$topdir/SPECS/"

rpmbuild --nodeps --define "_topdir $topdir" -ba "$topdir/SPECS/mkscript.spec"
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 rpmlint \
  "$topdir/SPECS/mkscript.spec" \
  "$topdir/SRPMS/"*.src.rpm \
  "$topdir/RPMS/noarch/"*.rpm
cp "$topdir/RPMS/noarch/"*.rpm "$topdir/SRPMS/"*.src.rpm "$dist_dir"/
printf 'Built RPM artifacts in %s\n' "$dist_dir"
