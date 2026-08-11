#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s --notes-file FILE\n' "$(basename "$0")" >&2
}

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

notes_file=

while [ "$#" -gt 0 ]; do
  case $1 in
    --notes-file)
      shift
      if [ "$#" -eq 0 ]; then
        usage
        exit 64
      fi
      notes_file=$1
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

if [ -z "$notes_file" ]; then
  usage
  exit 64
fi

if [ ! -f "$notes_file" ]; then
  printf 'Release notes file does not exist: %s\n' "$notes_file" >&2
  exit 66
fi

current_version=$(tr -d '\n' < "$repo_root/VERSION")

if [[ ! $current_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  printf 'VERSION must use semantic version format X.Y.Z: %s\n' "$current_version" >&2
  exit 65
fi

IFS=. read -r major minor patch <<<"$current_version"

current_deb_revision=$(
  sed -n '1s/^mkscript ([0-9][0-9.]*-\([0-9][0-9]*\)) unstable; urgency=medium$/\1/p' "$repo_root/debian/changelog"
)

if [[ ! $current_deb_revision =~ ^[0-9]+$ ]]; then
  printf 'Failed to determine Debian revision from debian/changelog.\n' >&2
  exit 65
fi

maintainer=$(
  sed -n 's/^ -- \(.*\)  [A-Z][a-z][a-z], .*/\1/p' "$repo_root/debian/changelog" | sed -n '1p'
)

if [ -z "$maintainer" ]; then
  printf 'Failed to determine maintainer from debian/changelog.\n' >&2
  exit 65
fi

notes=()
while IFS= read -r note_line || [ -n "$note_line" ]; do
  note_line=${note_line%$'\r'}
  note_line=${note_line#- }
  if [ -n "$note_line" ]; then
    notes+=("$note_line")
  fi
done < "$notes_file"

if [ "${#notes[@]}" -eq 0 ]; then
  printf 'Release notes file is empty: %s\n' "$notes_file" >&2
  exit 65
fi

next_version="$major.$minor.$((patch + 1))"
next_deb_version="$next_version-$current_deb_revision"
today_iso=$(LC_ALL=C date -u '+%Y-%m-%d')
debian_timestamp=$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')
rpm_date=$(LC_ALL=C date -u '+%a %b %d %Y')

render_changelog_md() {
  local file=$1

  awk -v version="$next_version" -v release_date="$today_iso" -v notes_file="$notes_file" '
    BEGIN {
      while ((getline line < notes_file) > 0) {
        gsub(/\r$/, "", line)
        sub(/^- /, "", line)
        if (line != "") {
          notes[++note_count] = line
        }
      }
      close(notes_file)
      inserted = 0
    }

    /^## \[/ && inserted == 0 {
      printf "## [%s] - %s\n\n", version, release_date
      printf "### Changed\n\n"
      for (i = 1; i <= note_count; i++) {
        printf "- %s\n", notes[i]
      }
      printf "\n"
      inserted = 1
    }

    { print }

    END {
      if (inserted == 0) {
        printf "\n## [%s] - %s\n\n", version, release_date
        printf "### Changed\n\n"
        for (i = 1; i <= note_count; i++) {
          printf "- %s\n", notes[i]
        }
        printf "\n"
      }
    }
  ' "$file"
}

render_debian_changelog() {
  local file=$1

  {
    printf 'mkscript (%s) unstable; urgency=medium\n\n' "$next_deb_version"
    for note_line in "${notes[@]}"; do
      printf '  * %s\n' "$note_line"
    done
    printf '\n -- %s  %s\n\n' "$maintainer" "$debian_timestamp"
    cat "$file"
  }
}

render_rpm_spec() {
  local file=$1

  awk \
    -v version="$next_version" \
    -v rpm_release="$current_deb_revision" \
    -v rpm_date="$rpm_date" \
    -v maintainer="$maintainer" \
    -v notes_file="$notes_file" '
    BEGIN {
      while ((getline line < notes_file) > 0) {
        gsub(/\r$/, "", line)
        sub(/^- /, "", line)
        if (line != "") {
          notes[++note_count] = line
        }
      }
      close(notes_file)
      inserted = 0
    }

    /^Version:[[:space:]]+/ {
      print "Version:        " version
      next
    }

    /^Release:[[:space:]]+/ {
      print "Release:        " rpm_release "%{?dist}"
      next
    }

    {
      print
      if (inserted == 0 && /^%changelog$/) {
        printf "* %s %s - %s-%s\n", rpm_date, maintainer, version, rpm_release
        for (i = 1; i <= note_count; i++) {
          printf "- %s\n", notes[i]
        }
        printf "\n"
        inserted = 1
      }
    }
  ' "$file"
}

sync_file() {
  local file=$1
  local renderer=$2
  local tmp_file

  tmp_file=$(mktemp)
  "$renderer" "$file" > "$tmp_file"
  mv "$tmp_file" "$file"
}

printf '%s\n' "$next_version" > "$repo_root/VERSION"
sync_file "$repo_root/CHANGELOG.md" render_changelog_md
sync_file "$repo_root/debian/changelog" render_debian_changelog
sync_file "$repo_root/packaging/rpm/mkscript.spec" render_rpm_spec
"$repo_root/scripts/sync-release-metadata.sh"
"$repo_root/scripts/validate-release-metadata.sh"
printf 'Bumped release metadata from %s to %s\n' "$current_version" "$next_version"
