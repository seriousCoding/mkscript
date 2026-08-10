#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s FORMULA_FILE\n' "$(basename "$0")" >&2
  exit 64
fi

formula_file=$1
tap_name='local/mkscript-ci'
brew_repo=$(brew --repository)
tap_dir="$brew_repo/Library/Taps/local/homebrew-mkscript-ci"

HOMEBREW_NO_AUTO_UPDATE=1 brew untap "$tap_name" >/dev/null 2>&1 || true
HOMEBREW_NO_AUTO_UPDATE=1 brew tap-new "$tap_name" >/dev/null
cp "$formula_file" "$tap_dir/Formula/mkscript.rb"

cleanup() {
  HOMEBREW_NO_AUTO_UPDATE=1 brew uninstall --force mkscript >/dev/null 2>&1 || true
  HOMEBREW_NO_AUTO_UPDATE=1 brew untap "$tap_name" >/dev/null 2>&1 || true
}

trap cleanup EXIT

HOMEBREW_NO_AUTO_UPDATE=1 brew install "$tap_name/mkscript"
HOMEBREW_NO_AUTO_UPDATE=1 brew test mkscript
printf 'Validated Homebrew formula: %s\n' "$formula_file"
