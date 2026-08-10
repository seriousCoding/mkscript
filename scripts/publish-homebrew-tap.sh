#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s FORMULA_FILE TAP_REPO\n' "$(basename "$0")" >&2
  exit 64
fi

: "${HOMEBREW_TAP_TOKEN:?HOMEBREW_TAP_TOKEN is required}"

formula_file=$1
tap_repo=$2
repo_root=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
)

# shellcheck source=scripts/release-vars.sh
source "$repo_root/scripts/release-vars.sh"

worktree=$(mktemp -d)

cleanup() {
  rm -rf "$worktree"
}

trap cleanup EXIT

git clone "https://x-access-token:${HOMEBREW_TAP_TOKEN}@github.com/${tap_repo}.git" "$worktree"
mkdir -p "$worktree/Formula"
cp "$formula_file" "$worktree/Formula/mkscript.rb"

if [ ! -f "$worktree/README.md" ]; then
  cat > "$worktree/README.md" <<'EOF'
# seriousCoding/homebrew-tap

Install with:

```bash
brew install seriousCoding/tap/mkscript
```
EOF
fi

if [ -z "$(git -C "$worktree" status --short -- Formula/mkscript.rb README.md)" ]; then
  printf 'Homebrew tap is already up to date.\n'
  exit 0
fi

git -C "$worktree" config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git -C "$worktree" config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
git -C "$worktree" add Formula/mkscript.rb README.md
git -C "$worktree" commit -m "Update mkscript to $MKSCRIPT_TAG"
git -C "$worktree" push origin HEAD
printf 'Published Homebrew formula to %s\n' "$tap_repo"
