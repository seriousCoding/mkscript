#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--tag TAG]\n' "$(basename "$0")" >&2
}

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

expected_tag=

while [ "$#" -gt 0 ]; do
  case $1 in
    --tag)
      shift
      if [ "$#" -eq 0 ]; then
        usage
        exit 64
      fi
      expected_tag=$1
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 64
      ;;
  esac
  shift
done

"$repo_root/scripts/sync-release-metadata.sh" --check "$repo_root"

if [ -n "$expected_tag" ] && [ "$expected_tag" != "$MKSCRIPT_TAG" ]; then
  printf 'Tag mismatch: expected %s from VERSION but received %s\n' "$MKSCRIPT_TAG" "$expected_tag" >&2
  exit 65
fi

top_changelog_entry=$(sed -n '/^## \[/ {p; q;}' "$repo_root/CHANGELOG.md")

if ! printf '%s\n' "$top_changelog_entry" | grep -Eq "^## \\[$MKSCRIPT_VERSION\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$"; then
  printf 'Top changelog entry does not match VERSION: %s\n' "$MKSCRIPT_VERSION" >&2
  exit 65
fi

if ! grep -Fqx "Version:        $MKSCRIPT_VERSION" "$repo_root/packaging/rpm/mkscript.spec"; then
  printf 'RPM spec version does not match VERSION: %s\n' "$MKSCRIPT_VERSION" >&2
  exit 65
fi

if ! grep -Fqx "Release:        ${MKSCRIPT_RPM_RELEASE}%{?dist}" "$repo_root/packaging/rpm/mkscript.spec"; then
  printf 'RPM spec release does not match expected release: %s\n' "$MKSCRIPT_RPM_RELEASE" >&2
  exit 65
fi

if ! grep -Fqx "mkscript (${MKSCRIPT_DEB_VERSION}) unstable; urgency=medium" "$repo_root/debian/changelog"; then
  printf 'Debian changelog version does not match VERSION: %s\n' "$MKSCRIPT_DEB_VERSION" >&2
  exit 65
fi

if ! grep -Fq "\"mkscript ${MKSCRIPT_VERSION}\"" "$repo_root/mkscript.1"; then
  printf 'Man page version does not match VERSION: %s\n' "$MKSCRIPT_VERSION" >&2
  exit 65
fi

printf 'Release metadata matches VERSION %s\n' "$MKSCRIPT_VERSION"
