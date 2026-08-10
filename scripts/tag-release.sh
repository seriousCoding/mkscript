#!/usr/bin/env bash
set -euo pipefail

repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

"$repo_root/scripts/validate-release-metadata.sh"

if git -C "$repo_root" rev-parse "$MKSCRIPT_TAG" >/dev/null 2>&1; then
  printf 'Tag already exists locally: %s\n' "$MKSCRIPT_TAG" >&2
  exit 65
fi

if git -C "$repo_root" ls-remote --exit-code --tags origin "$MKSCRIPT_TAG" >/dev/null 2>&1; then
  printf 'Tag already exists on origin: %s\n' "$MKSCRIPT_TAG" >&2
  exit 65
fi

git -C "$repo_root" tag -a "$MKSCRIPT_TAG" -m "Release $MKSCRIPT_TAG"
git -C "$repo_root" push origin "$MKSCRIPT_TAG"
printf 'Created and pushed tag: %s\n' "$MKSCRIPT_TAG"
