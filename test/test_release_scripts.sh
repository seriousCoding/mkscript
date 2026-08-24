#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equals() {
  local expected=$1
  local actual=$2
  local message=$3

  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\nExpected: %s\nActual: %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack=$1
  local needle=$2
  local message=$3

  case $haystack in
    *"$needle"*)
      ;;
    *)
      printf 'FAIL: %s\nMissing: %s\nContent: %s\n' "$message" "$needle" "$haystack" >&2
      exit 1
      ;;
  esac
}

increment_patch_version() {
  local version=$1
  local major
  local minor
  local patch

  IFS=. read -r major minor patch <<<"$version"
  printf '%s.%s.%s\n' "$major" "$minor" "$((patch + 1))"
}

fixture_root=$(mktemp -d)
cleanup() {
  rm -rf "$fixture_root"
}
trap cleanup EXIT

mkdir -p "$fixture_root/scripts" "$fixture_root/debian" "$fixture_root/packaging/rpm"
cp "$repo_root/VERSION" "$fixture_root/VERSION"
cp "$repo_root/CHANGELOG.md" "$fixture_root/CHANGELOG.md"
cp "$repo_root/mkscript.1" "$fixture_root/mkscript.1"
cp "$repo_root/debian/changelog" "$fixture_root/debian/changelog"
cp "$repo_root/packaging/rpm/mkscript.spec" "$fixture_root/packaging/rpm/mkscript.spec"
cp \
  "$repo_root/scripts/bump-version.sh" \
  "$repo_root/scripts/release-vars.sh" \
  "$repo_root/scripts/sync-release-metadata.sh" \
  "$repo_root/scripts/validate-release-metadata.sh" \
  "$fixture_root/scripts/"

cat > "$fixture_root/release-notes.txt" <<'EOF'
Add automated patch release commits on successful main CI runs
Keep release metadata in sync with changelog, Debian, and RPM outputs
EOF

starting_version=$(tr -d '\n' < "$fixture_root/VERSION")
expected_version=$(increment_patch_version "$starting_version")

"$fixture_root/scripts/bump-version.sh" --notes-file "$fixture_root/release-notes.txt" >/dev/null
"$fixture_root/scripts/validate-release-metadata.sh" >/dev/null

actual_version=$(tr -d '\n' < "$fixture_root/VERSION")
assert_equals "$expected_version" "$actual_version" 'bump-version should increment the patch version'

changelog_head=$(sed -n '1,12p' "$fixture_root/CHANGELOG.md")
assert_contains "$changelog_head" "## [$expected_version] - " 'CHANGELOG.md should add a new top entry'
assert_contains "$changelog_head" '- Add automated patch release commits on successful main CI runs' 'CHANGELOG.md should include the first release note'

debian_head=$(sed -n '1,12p' "$fixture_root/debian/changelog")
assert_contains "$debian_head" "mkscript (${expected_version}-1) unstable; urgency=medium" 'debian/changelog should add a new release stanza'
assert_contains "$debian_head" '  * Keep release metadata in sync with changelog, Debian, and RPM outputs' 'debian/changelog should include the second release note'

spec_head=$(cat "$fixture_root/packaging/rpm/mkscript.spec")
assert_contains "$spec_head" "Version:        $expected_version" 'RPM spec should update the version field'
assert_contains "$spec_head" '%changelog' 'RPM spec should keep a changelog section'
assert_contains "$spec_head" " - ${expected_version}-1" 'RPM spec should add a new top changelog entry'
assert_contains "$spec_head" '- Add automated patch release commits on successful main CI runs' 'RPM spec should include release notes in %changelog'

manpage_head=$(sed -n '1p' "$fixture_root/mkscript.1")
assert_contains "$manpage_head" "\"mkscript $expected_version\"" 'mkscript.1 should update the rendered version'

tag_workflow=$(cat "$repo_root/.github/workflows/tag-from-version.yml")
assert_contains "$tag_workflow" "release_tag=\"v\$(tr -d '\\r\\n' < VERSION)\"" 'release workflow should derive the bumped tag in the current shell'
assert_contains "$tag_workflow" "git commit -m \"chore(release): \$release_tag\"" 'release workflow should commit using the derived bumped tag'

printf 'Release script tests passed.\n'
