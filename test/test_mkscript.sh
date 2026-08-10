#!/usr/bin/env bash
set -euo pipefail

: "${MKSCRIPT_UNDER_TEST:?MKSCRIPT_UNDER_TEST is required}"
: "${VERSION:?VERSION is required}"

tests_run=0
START_DIR=$(pwd)

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

RUN_STATUS=0
RUN_STDOUT=''
RUN_STDERR=''

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

test_plain_script_creation() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" hello-world
  assert_status 0 "$RUN_STATUS" 'plain script creation should succeed'
  assert_contains "$RUN_STDOUT" 'Created script: hello-world' 'success output should mention the target path'
  assert_file_equals hello-world $'#!/usr/bin/env bash\n' 'plain script should only contain the shebang'
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
  assert_file_equals strict-short $'#!/usr/bin/env bash\nset -euo pipefail\n' 'short strict flag should add strict mode'
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
  assert_file_equals "$target" $'#!/usr/bin/env bash\nset -euo pipefail\n' 'long strict flag should add strict mode'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_help_output() {
  run_capture "$MKSCRIPT_UNDER_TEST" --help
  assert_status 0 "$RUN_STATUS" 'help should exit successfully'
  assert_contains "$RUN_STDOUT" 'Usage: mkscript [OPTION]... PATH' 'help should show usage'
  assert_contains "$RUN_STDOUT" '-s, --strict' 'help should document strict mode'
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

printf 'All %s tests passed.\n' "$tests_run"
