#!/usr/bin/env bash
# assertions.sh — Reusable assertion helpers for RW smoke tests
set -euo pipefail

_PASS=0
_FAIL=0
_TOTAL=0

# Colors
_GREEN='\033[0;32m'
_RED='\033[0;31m'
_YELLOW='\033[0;33m'
_NC='\033[0m'

assert_pass() {
  local label="$1"
  ((_PASS++)) || true
  ((_TOTAL++)) || true
  printf "  ${_GREEN}✓${_NC} %s\n" "$label"
}

assert_fail() {
  local label="$1"
  local detail="${2:-}"
  ((_FAIL++)) || true
  ((_TOTAL++)) || true
  printf "  ${_RED}✗${_NC} %s" "$label"
  [ -n "$detail" ] && printf " — %s" "$detail"
  printf "\n"
}

# --- File assertions ---

assert_file_exists() {
  local path="$1"
  local label="${2:-$path exists}"
  if [ -e "$path" ]; then
    assert_pass "$label"
  else
    assert_fail "$label" "not found: $path"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local label="${2:-$path does not exist}"
  if [ ! -e "$path" ]; then
    assert_pass "$label"
  else
    assert_fail "$label" "unexpectedly found: $path"
  fi
}

assert_dir_exists() {
  local path="$1"
  local label="${2:-$path is a directory}"
  if [ -d "$path" ]; then
    assert_pass "$label"
  else
    assert_fail "$label" "not a directory: $path"
  fi
}

assert_file_contains() {
  local path="$1"
  local pattern="$2"
  local label="${3:-$path contains '$pattern'}"
  if [ -f "$path" ] && grep -qF "$pattern" "$path"; then
    assert_pass "$label"
  else
    assert_fail "$label" "pattern not found in $path"
  fi
}

assert_file_not_contains() {
  local path="$1"
  local pattern="$2"
  local label="${3:-$path does not contain '$pattern'}"
  if [ -f "$path" ] && grep -qF "$pattern" "$path"; then
    assert_fail "$label" "pattern unexpectedly found in $path"
  else
    assert_pass "$label"
  fi
}

assert_file_line_match() {
  local path="$1"
  local regex="$2"
  local label="${3:-$path matches regex}"
  if [ -f "$path" ] && grep -qE "$regex" "$path"; then
    assert_pass "$label"
  else
    assert_fail "$label" "regex not matched in $path"
  fi
}

# --- PROGRESS-specific assertions ---

assert_progress_status() {
  local progress_file="$1"
  local task_id="$2"
  local expected_status="$3"
  local label="PROGRESS: $task_id is $expected_status"
  if [ -f "$progress_file" ] && grep -qE "^\| *$task_id *\|.*\| *$expected_status *\|" "$progress_file"; then
    assert_pass "$label"
  else
    assert_fail "$label"
  fi
}

assert_progress_log_contains() {
  local progress_file="$1"
  local token="$2"
  local label="PROGRESS Log contains '$token'"
  if [ -f "$progress_file" ] && grep -qF "$token" "$progress_file"; then
    assert_pass "$label"
  else
    assert_fail "$label"
  fi
}

# --- Feature file assertions ---

assert_feature_status() {
  local feature_file="$1"
  local expected_status="$2"
  local label="Feature status is $expected_status"
  if [ -f "$feature_file" ] && grep -qF "Status: $expected_status" "$feature_file"; then
    assert_pass "$label"
  else
    assert_fail "$label" "in $feature_file"
  fi
}

# --- Git assertions ---

assert_git_commit_exists() {
  local dir="$1"
  local pattern="$2"
  local label="${3:-git log contains '$pattern'}"
  if (cd "$dir" && git log --oneline 2>/dev/null | grep -qF "$pattern"); then
    assert_pass "$label"
  else
    assert_fail "$label"
  fi
}

assert_git_clean() {
  local dir="$1"
  local label="git working tree is clean"
  if (cd "$dir" && [ -z "$(git status --porcelain 2>/dev/null)" ]); then
    assert_pass "$label"
  else
    assert_fail "$label"
  fi
}

assert_git_commit_count() {
  local dir="$1"
  local expected="$2"
  local label="${3:-git commit count is $expected}"
  local count="0"
  if ! count="$(cd "$dir" && git rev-list --count HEAD 2>/dev/null)"; then
    count="0"
  fi
  if [ "$count" -eq "$expected" ]; then
    assert_pass "$label"
  else
    assert_fail "$label" "got $count"
  fi
}

# --- Command assertions ---

assert_command_succeeds() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    assert_pass "$label"
  else
    assert_fail "$label" "command failed: $*"
  fi
}

assert_command_output_contains() {
  local label="$1"
  local pattern="$2"
  shift 2
  local output
  output="$("$@" 2>&1)" || true
  if echo "$output" | grep -qF "$pattern"; then
    assert_pass "$label"
  else
    assert_fail "$label" "output did not contain '$pattern'"
  fi
}

# --- File count assertion ---

assert_file_count() {
  local dir="$1"
  local pattern="$2"
  local min="$3"
  local max="$4"
  local label="${5:-$dir has $min-$max files matching $pattern}"
  local count
  count=$(find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -ge "$min" ] && [ "$count" -le "$max" ]; then
    assert_pass "$label (found $count)"
  else
    assert_fail "$label" "found $count, expected $min-$max"
  fi
}

# --- Summary ---

print_summary() {
  echo ""
  if [ "$_FAIL" -eq 0 ]; then
    printf "${_GREEN}=== %d/%d PASSED ===${_NC}\n" "$_PASS" "$_TOTAL"
  else
    printf "${_RED}=== %d/%d PASSED, %d FAILED ===${_NC}\n" "$_PASS" "$_TOTAL" "$_FAIL"
  fi
  return "$_FAIL"
}
