#!/usr/bin/env bash
set -euo pipefail

: "${MKSCRIPT_UNDER_TEST:?MKSCRIPT_UNDER_TEST is required}"
: "${VERSION:?VERSION is required}"

tests_run=0
START_DIR=$(pwd)
CURRENT_OS=$(uname -s)

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

assert_status() {
  local expected=$1
  local actual=$2
  local message=$3

  if [ "$expected" -ne "$actual" ]; then
    printf 'FAIL: %s\nExpected status: %s\nActual status: %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_equals() {
  local file=$1
  local expected_content=$2
  local message=$3
  local expected_file

  expected_file=$(mktemp)
  printf '%s' "$expected_content" > "$expected_file"

  if ! cmp -s "$file" "$expected_file"; then
    printf 'FAIL: %s\n' "$message" >&2
    printf 'Expected file contents:\n' >&2
    cat "$expected_file" >&2
    printf 'Actual file contents:\n' >&2
    cat "$file" >&2
    rm -f "$expected_file"
    exit 1
  fi

  rm -f "$expected_file"
}

assert_executable() {
  local file=$1
  local message=$2

  if [ ! -x "$file" ]; then
    fail "$message"
  fi
}

assert_not_exists() {
  local path=$1
  local message=$2

  if [ -e "$path" ] || [ -L "$path" ]; then
    fail "$message"
  fi
}

assert_symlink_target() {
  local path=$1
  local expected_target=$2
  local message=$3
  local actual_target

  if [ ! -L "$path" ]; then
    fail "$message"
  fi

  actual_target=$(readlink "$path")
  assert_equals "$expected_target" "$actual_target" "$message"
}

parent_dir() {
  local path=$1
  local parent

  case $path in
    */*)
      parent=${path%/*}
      if [ -z "$parent" ]; then
        printf '/\n'
      else
        printf '%s\n' "$parent"
      fi
      ;;
    *)
      printf '.\n'
      ;;
  esac
}

path_has_entry() {
  local needle=$1
  local path_value=${2-}
  local path_entry
  local old_ifs=$IFS

  IFS=:
  for path_entry in $path_value; do
    if [ "$path_entry" = "$needle" ]; then
      IFS=$old_ifs
      return 0
    fi
  done
  IFS=$old_ifs

  return 1
}

expected_global_dir() {
  local home_dir=$1
  local path_value=$2
  local path_entry
  local parent_name
  local old_ifs=$IFS

  if [ "$CURRENT_OS" = 'Darwin' ]; then
    if path_has_entry "$home_dir/.local/bin" "$path_value"; then
      printf '%s/.local/bin\n' "$home_dir"
      return 0
    fi

    if path_has_entry "$home_dir/bin" "$path_value"; then
      printf '%s/bin\n' "$home_dir"
      return 0
    fi

    IFS=:
    for path_entry in $path_value; do
      case $path_entry in
        "$home_dir"/*/bin)
          parent_name=${path_entry%/bin}
          parent_name=${parent_name##*/}
          case $parent_name in
            *local*)
              IFS=$old_ifs
              printf '%s\n' "$path_entry"
              return 0
              ;;
          esac
          ;;
      esac
    done
    IFS=$old_ifs
  fi

  printf '%s/.local/bin\n' "$home_dir"
}

expected_global_link_path() {
  local home_dir=$1
  local path_value=$2
  local target_name=$3

  printf '%s/%s\n' "$(expected_global_dir "$home_dir" "$path_value")" "$target_name"
}

default_global_test_path() {
  local home_dir=$1

  printf '%s/.new_local/bin:/usr/bin:/bin\n' "$home_dir"
}

RUN_STATUS=0
RUN_STDOUT=''
RUN_STDERR=''

current_creator_name() {
  local creator

  creator=$(id -un 2>/dev/null || true)
  if [ -z "$creator" ]; then
    creator=${LOGNAME:-${USER:-}}
  fi
  if [ -z "$creator" ]; then
    fail 'failed to determine creator name for test expectations'
  fi

  printf '%s\n' "$creator"
}

current_created_date() {
  local created_date

  created_date=$(date '+%Y-%m-%d' 2>/dev/null || true)
  if [ -z "$created_date" ]; then
    fail 'failed to determine current date for test expectations'
  fi

  printf '%s\n' "$created_date"
}

expected_script_content() {
  local script_name=$1
  local strict_enabled=$2

  printf '#!/usr/bin/env bash\n'
  printf '# Script: %s\n' "$script_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  if [ "$strict_enabled" -eq 1 ]; then
    printf 'set -euo pipefail\n'
  fi
}

assert_script_file_equals() {
  local file=$1
  local script_name=$2
  local strict_enabled=$3
  local message=$4
  local expected_file

  expected_file=$(mktemp)
  expected_script_content "$script_name" "$strict_enabled" > "$expected_file"

  if ! cmp -s "$file" "$expected_file"; then
    printf 'FAIL: %s\n' "$message" >&2
    printf 'Expected file contents:\n' >&2
    cat "$expected_file" >&2
    printf 'Actual file contents:\n' >&2
    cat "$file" >&2
    rm -f "$expected_file"
    exit 1
  fi

  rm -f "$expected_file"
}

run_capture() {
  local stdout_file
  local stderr_file

  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  if "$@" >"$stdout_file" 2>"$stderr_file"; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi

  RUN_STDOUT=$(cat "$stdout_file")
  RUN_STDERR=$(cat "$stderr_file")

  rm -f "$stdout_file" "$stderr_file"
}

run_capture_with_input() {
  local input=$1
  local stdin_file
  local stdout_file
  local stderr_file

  shift

  stdin_file=$(mktemp)
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  printf '%s' "$input" > "$stdin_file"

  if "$@" <"$stdin_file" >"$stdout_file" 2>"$stderr_file"; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi

  RUN_STDOUT=$(cat "$stdout_file")
  RUN_STDERR=$(cat "$stderr_file")

  rm -f "$stdin_file" "$stdout_file" "$stderr_file"
}

test_plain_script_creation() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" hello-world
  assert_status 0 "$RUN_STATUS" 'plain script creation should succeed'
  assert_contains "$RUN_STDOUT" 'Created script: hello-world' 'success output should mention the target path'
  assert_script_file_equals hello-world hello-world 0 'plain script should include the default header'
  assert_executable hello-world 'plain script should be executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_short_strict_mode() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -s strict-short
  assert_status 0 "$RUN_STATUS" 'short strict flag should succeed'
  assert_script_file_equals strict-short strict-short 1 'short strict flag should add strict mode after the default header'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_long_strict_mode_with_absolute_path() {
  local sandbox
  local target

  sandbox=$(mktemp -d)
  target="$sandbox/path with spaces.sh"
  run_capture "$MKSCRIPT_UNDER_TEST" --strict "$target"
  assert_status 0 "$RUN_STATUS" 'long strict flag should succeed with an absolute path'
  assert_script_file_equals "$target" 'path with spaces.sh' 1 'long strict flag should add strict mode after the default header'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_help_output() {
  run_capture "$MKSCRIPT_UNDER_TEST" --help
  assert_status 0 "$RUN_STATUS" 'help should exit successfully'
  assert_contains "$RUN_STDOUT" 'Usage: mkscript [OPTION]... PATH' 'help should show usage'
  assert_contains "$RUN_STDOUT" '-s, --strict' 'help should document strict mode'
  assert_contains "$RUN_STDOUT" '-g, --global' 'help should document global mode'
  assert_contains "$RUN_STDOUT" '-l, --link' 'help should document link-only mode'
  assert_contains "$RUN_STDOUT" '-c' 'help should document link-check mode'
  assert_contains "$RUN_STDOUT" '-r' 'help should document link-removal mode'
}

test_version_output() {
  run_capture "$MKSCRIPT_UNDER_TEST" --version
  assert_status 0 "$RUN_STATUS" 'version should exit successfully'
  assert_equals "mkscript $VERSION" "$RUN_STDOUT" 'version output should match VERSION'
}

test_overwrite_refusal() {
  local sandbox

  sandbox=$(mktemp -d)
  printf 'keep me\n' > "$sandbox/existing"
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox/existing"
  assert_status 73 "$RUN_STATUS" 'existing files should not be overwritten'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing path' 'existing file refusal should explain the problem'
  assert_file_equals "$sandbox/existing" $'keep me\n' 'existing file should remain unchanged'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_missing_output_path() {
  run_capture "$MKSCRIPT_UNDER_TEST"
  assert_status 64 "$RUN_STATUS" 'missing output path should be a usage error'
  assert_contains "$RUN_STDERR" 'missing output path' 'missing output path should be explained'
}

test_invalid_option() {
  run_capture "$MKSCRIPT_UNDER_TEST" --bogus
  assert_status 64 "$RUN_STATUS" 'unknown options should be a usage error'
  assert_contains "$RUN_STDERR" 'unknown option: --bogus' 'unknown options should be explained'
}

test_missing_parent_directory() {
  local sandbox

  sandbox=$(mktemp -d)
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox/missing-parent/new-script"
  assert_status 73 "$RUN_STATUS" 'missing parent directory should be a create error'
  assert_contains "$RUN_STDERR" 'parent directory does not exist' 'missing parent directory should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_directory_target_refusal() {
  local sandbox

  sandbox=$(mktemp -d)
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox"
  assert_status 73 "$RUN_STATUS" 'directories should not be overwritten'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing directory' 'directory targets should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_with_trailing_strict_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -g test -s
  assert_status 0 "$RUN_STATUS" 'global mode should allow strict mode after the script name'
  assert_script_file_equals test test 1 'global strict script should include the default header and strict mode'
  assert_symlink_target "$expected_link" "$expected_target" 'global link should point to the created script'
  assert_contains "$RUN_STDOUT" 'Created global link:' 'global mode should report the created link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_with_trailing_global_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 0 "$RUN_STATUS" 'global mode should allow the global flag after the script name'
  assert_script_file_equals test test 0 'global mode without strict should still include the default header'
  assert_symlink_target "$expected_link" "$expected_target" 'trailing global flag should create the expected symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_refuses_existing_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link
  local expected_dir

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  expected_dir=$(parent_dir "$expected_link")
  mkdir -p "$expected_dir"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 73 "$RUN_STATUS" 'global mode should refuse to overwrite an existing global path'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing global path' 'global path conflicts should be explained'
  assert_not_exists "$sandbox/test" 'global path conflicts should not create a local script'
  assert_file_equals "$expected_link" $'busy\n' 'existing global paths should remain unchanged'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_falls_back_to_local_bin() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/fallback
  path_value='/usr/bin:/bin'
  expected_link="$home_dir/.local/bin/fallback"
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" fallback -g
  assert_status 0 "$RUN_STATUS" 'global mode should fall back to ~/.local/bin when no preferred path is present'
  assert_symlink_target "$expected_link" "$expected_target" 'fallback global path should point to the created script'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_links_existing_file() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -l test
  assert_status 0 "$RUN_STATUS" 'link-only mode should link an existing file after confirmation'
  assert_contains "$RUN_STDOUT" "Are you sure you want to link source path 'test' to '$expected_link'?" 'link-only mode should prompt for confirmation'
  assert_symlink_target "$expected_link" "$expected_target" 'link-only mode should create the expected symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_links_existing_sh_file_with_trailing_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test.sh
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test.sh)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test.sh"
  chmod 755 "$sandbox/test.sh"
  cd "$sandbox"
  run_capture_with_input $'yes\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test.sh -l
  assert_status 0 "$RUN_STATUS" 'link-only mode should allow the link flag after the path'
  assert_contains "$RUN_STDOUT" "Are you sure you want to link source path 'test.sh' to '$expected_link'?" 'trailing link flag should still prompt for confirmation'
  assert_symlink_target "$expected_link" "$expected_target" 'trailing link flag should create the expected symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_refuses_missing_local_target() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" missing-script)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -l missing-script
  assert_status 73 "$RUN_STATUS" 'link-only mode should refuse missing local files'
  assert_contains "$RUN_STDERR" 'cannot link missing path' 'missing local targets should be explained'
  assert_not_exists "$expected_link" 'missing local targets should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_refuses_existing_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link
  local expected_dir

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  expected_dir=$(parent_dir "$expected_link")
  mkdir -p "$expected_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -l test
  assert_status 73 "$RUN_STATUS" 'link-only mode should refuse to overwrite an existing global path'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing global path' 'existing global paths should be explained for link-only mode'
  assert_file_equals "$expected_link" $'busy\n' 'existing global paths should remain unchanged in link-only mode'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_cancellation_refuses_to_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture_with_input $'n\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -l test
  assert_status 73 "$RUN_STATUS" 'link-only mode should stop when confirmation is denied'
  assert_contains "$RUN_STDERR" 'link cancelled' 'denied confirmation should be explained'
  assert_not_exists "$expected_link" 'denied confirmation should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_rejects_global_flag_combination() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -l test -g
  assert_status 64 "$RUN_STATUS" 'link-only mode should reject the global flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --link with --global' 'the rejected global flag combination should be explained'
  assert_not_exists "$expected_link" 'invalid link/global combinations should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_link_mode_rejects_strict_flag_combination() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -l -s
  assert_status 64 "$RUN_STATUS" 'link-only mode should reject the strict flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --link with --strict' 'the rejected strict flag combination should be explained'
  assert_not_exists "$expected_link" 'invalid link/strict combinations should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_reports_existing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test
  assert_status 0 "$RUN_STATUS" 'check mode should succeed when the global link exists'
  assert_contains "$RUN_STDOUT" "$expected_link" 'check mode should print the global link path when it exists'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_reports_missing_link_with_trailing_flag() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -c
  assert_status 1 "$RUN_STATUS" 'check mode should return 1 when the global link is missing'
  assert_contains "$RUN_STDOUT" "$expected_link" 'check mode should report the checked path when the link is missing'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_refuses_non_symlink_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test
  assert_status 73 "$RUN_STATUS" 'check mode should refuse non-symlink global paths'
  assert_contains "$RUN_STDERR" 'global path exists but is not a symlink' 'check mode should explain conflicting non-symlink global paths'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_rejects_global_flag_combination() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test -g
  assert_status 64 "$RUN_STATUS" 'check mode should reject the global flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -c with --global' 'the rejected check/global combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_removes_existing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 0 "$RUN_STATUS" 'remove mode should remove an existing global link after confirmation'
  assert_contains "$RUN_STDOUT" "Are you sure you want to remove link for 'test' from '$expected_link'?" 'remove mode should prompt before deleting a link'
  assert_contains "$RUN_STDOUT" "Removed link for 'test' from '$expected_link'" 'remove mode should report the removed link path'
  assert_not_exists "$expected_link" 'remove mode should delete the symlink after confirmation'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_removes_existing_link_with_trailing_flag() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'yes\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -r
  assert_status 0 "$RUN_STATUS" 'remove mode should allow the remove flag after the target'
  assert_not_exists "$expected_link" 'trailing remove flag should delete the symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_reports_missing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 1 "$RUN_STATUS" 'remove mode should return 1 when no global link exists'
  assert_contains "$RUN_STDOUT" "$expected_link" 'remove mode should report the missing link path'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_refuses_non_symlink_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 73 "$RUN_STATUS" 'remove mode should refuse non-symlink global paths'
  assert_contains "$RUN_STDERR" 'global path exists but is not a symlink' 'remove mode should explain conflicting non-symlink global paths'
  assert_file_equals "$expected_link" $'busy\n' 'remove mode should leave regular files untouched'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_cancellation_refuses_to_delete() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'n\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 73 "$RUN_STATUS" 'remove mode should stop when confirmation is denied'
  assert_contains "$RUN_STDERR" 'link removal cancelled' 'denied confirmation should be explained for remove mode'
  if [ ! -L "$expected_link" ]; then
    fail 'denied confirmation should leave the symlink in place'
  fi
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_rejects_strict_flag_combination() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test -s
  assert_status 64 "$RUN_STATUS" 'remove mode should reject the strict flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -r with --strict' 'the rejected remove/strict combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

run_test() {
  local name=$1

  tests_run=$((tests_run + 1))
  "$name"
  printf 'PASS: %s\n' "$name"
}

run_test test_plain_script_creation
run_test test_short_strict_mode
run_test test_long_strict_mode_with_absolute_path
run_test test_help_output
run_test test_version_output
run_test test_overwrite_refusal
run_test test_missing_output_path
run_test test_invalid_option
run_test test_missing_parent_directory
run_test test_directory_target_refusal
run_test test_global_mode_with_trailing_strict_flag
run_test test_global_mode_with_trailing_global_flag
run_test test_global_mode_refuses_existing_global_path
run_test test_global_mode_falls_back_to_local_bin
run_test test_link_mode_links_existing_file
run_test test_link_mode_links_existing_sh_file_with_trailing_flag
run_test test_link_mode_refuses_missing_local_target
run_test test_link_mode_refuses_existing_global_path
run_test test_link_mode_cancellation_refuses_to_link
run_test test_link_mode_rejects_global_flag_combination
run_test test_link_mode_rejects_strict_flag_combination
run_test test_check_mode_reports_existing_link
run_test test_check_mode_reports_missing_link_with_trailing_flag
run_test test_check_mode_refuses_non_symlink_global_path
run_test test_check_mode_rejects_global_flag_combination
run_test test_remove_mode_removes_existing_link
run_test test_remove_mode_removes_existing_link_with_trailing_flag
run_test test_remove_mode_reports_missing_link
run_test test_remove_mode_refuses_non_symlink_global_path
run_test test_remove_mode_cancellation_refuses_to_delete
run_test test_remove_mode_rejects_strict_flag_combination

printf 'All %s tests passed.\n' "$tests_run"
