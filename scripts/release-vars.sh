#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

version=$(tr -d '\n' < "$repo_root/VERSION")

if [ -z "$version" ]; then
  printf 'VERSION is empty.\n' >&2
  exit 65
fi

if [[ ! $version =~ ^[0-9]+(\.[0-9]+){2}$ ]]; then
  printf 'VERSION must use semantic version format X.Y.Z: %s\n' "$version" >&2
  exit 65
fi

readonly MKSCRIPT_GITHUB_REPO='seriousCoding/mkscript'
readonly MKSCRIPT_GITHUB_URL="https://github.com/$MKSCRIPT_GITHUB_REPO"
readonly MKSCRIPT_VERSION=$version
readonly MKSCRIPT_TAG="v$MKSCRIPT_VERSION"
readonly MKSCRIPT_DEB_REVISION=1
readonly MKSCRIPT_DEB_VERSION="${MKSCRIPT_VERSION}-${MKSCRIPT_DEB_REVISION}"
readonly MKSCRIPT_RPM_RELEASE=$MKSCRIPT_DEB_REVISION
readonly MKSCRIPT_SOURCE_ARCHIVE="mkscript-${MKSCRIPT_VERSION}.tar.gz"
readonly MKSCRIPT_DEB_PACKAGE="mkscript_${MKSCRIPT_DEB_VERSION}_all.deb"
readonly MKSCRIPT_RELEASE_BASE_URL="${MKSCRIPT_GITHUB_URL}/releases/download/${MKSCRIPT_TAG}"
readonly MKSCRIPT_RELEASE_SOURCE_URL="${MKSCRIPT_RELEASE_BASE_URL}/${MKSCRIPT_SOURCE_ARCHIVE}"

sha256_file() {
  local file=$1

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return 0
  fi

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return 0
  fi

  printf 'Neither sha256sum nor shasum is available.\n' >&2
  exit 69
}

print_vars() {
  printf 'MKSCRIPT_GITHUB_REPO=%s\n' "$MKSCRIPT_GITHUB_REPO"
  printf 'MKSCRIPT_GITHUB_URL=%s\n' "$MKSCRIPT_GITHUB_URL"
  printf 'MKSCRIPT_VERSION=%s\n' "$MKSCRIPT_VERSION"
  printf 'MKSCRIPT_TAG=%s\n' "$MKSCRIPT_TAG"
  printf 'MKSCRIPT_DEB_VERSION=%s\n' "$MKSCRIPT_DEB_VERSION"
  printf 'MKSCRIPT_RPM_RELEASE=%s\n' "$MKSCRIPT_RPM_RELEASE"
  printf 'MKSCRIPT_SOURCE_ARCHIVE=%s\n' "$MKSCRIPT_SOURCE_ARCHIVE"
  printf 'MKSCRIPT_DEB_PACKAGE=%s\n' "$MKSCRIPT_DEB_PACKAGE"
  printf 'MKSCRIPT_RELEASE_BASE_URL=%s\n' "$MKSCRIPT_RELEASE_BASE_URL"
  printf 'MKSCRIPT_RELEASE_SOURCE_URL=%s\n' "$MKSCRIPT_RELEASE_SOURCE_URL"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1-}" in
    '')
      ;;
    --print|--github-env)
      print_vars
      ;;
    *)
      printf 'Usage: %s [--print|--github-env]\n' "$(basename "$0")" >&2
      exit 64
      ;;
  esac
fi
