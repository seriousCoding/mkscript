#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--check] [TARGET_ROOT]\n' "$(basename "$0")" >&2
}

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

check_only=false
target_root=$repo_root
target_root_set=false

while [ "$#" -gt 0 ]; do
  case $1 in
    --check)
      check_only=true
      ;;
    --help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 64
      ;;
    *)
      if [ "$target_root_set" = true ]; then
        usage
        exit 64
      fi
      target_root=$1
      target_root_set=true
      ;;
  esac
  shift
done

# shellcheck disable=SC2317,SC2329
render_debian_changelog() {
  local file=$1

  awk -v deb_version="$MKSCRIPT_DEB_VERSION" '
    NR == 1 {
      sub(/\([^)]*\)/, "(" deb_version ")")
    }
    { print }
  ' "$file"
}

# shellcheck disable=SC2317,SC2329
render_rpm_spec() {
  local file=$1

  awk -v version="$MKSCRIPT_VERSION" -v rpm_release="$MKSCRIPT_RPM_RELEASE" '
    BEGIN {
      in_changelog = 0
      changelog_done = 0
    }

    /^Version:[[:space:]]+/ {
      print "Version:        " version
      next
    }

    /^Release:[[:space:]]+/ {
      print "Release:        " rpm_release "%{?dist}"
      next
    }

    /^%changelog$/ {
      in_changelog = 1
      print
      next
    }

    in_changelog && !changelog_done && /^\* / {
      sub(/ - [0-9]+(\.[0-9]+){2}-[0-9]+$/, " - " version "-" rpm_release)
      changelog_done = 1
      print
      next
    }

    { print }
  ' "$file"
}

# shellcheck disable=SC2317,SC2329
render_man_page() {
  local file=$1

  awk -v version="$MKSCRIPT_VERSION" '
    NR == 1 {
      gsub(/"mkscript [^"]+"/, "\"mkscript " version "\"")
    }
    { print }
  ' "$file"
}

sync_file() {
  local file=$1
  local renderer=$2
  local tmp_file

  if [ ! -f "$file" ]; then
    return 0
  fi

  tmp_file=$(mktemp)
  "$renderer" "$file" > "$tmp_file"

  if cmp -s "$file" "$tmp_file"; then
    rm -f "$tmp_file"
    return 0
  fi

  if [ "$check_only" = true ]; then
    printf 'Out-of-date release metadata: %s\n' "$file" >&2
    diff -u "$file" "$tmp_file" || true
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$file"
  printf 'Updated release metadata: %s\n' "$file"
}

status=0
sync_file "$target_root/debian/changelog" render_debian_changelog || status=$?
sync_file "$target_root/packaging/rpm/mkscript.spec" render_rpm_spec || status=$?
sync_file "$target_root/mkscript.1" render_man_page || status=$?

exit "$status"
