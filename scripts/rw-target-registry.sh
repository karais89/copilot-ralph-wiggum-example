#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1"
  exit 1
}

read_first_non_empty() {
  local file="$1"
  [ -f "$file" ] || return 0
  sed -n '/./{p;q;}' "$file"
}

normalize_target_root() {
  local raw="$1"
  if [ "${raw#TEST_HARNESS:}" != "$raw" ]; then
    printf '%s\n' "${raw#TEST_HARNESS:}"
  else
    printf '%s\n' "$raw"
  fi
}

validate_target_id() {
  local target_id="$1"
  printf '%s\n' "$target_id" | rg -q '^[A-Za-z0-9][A-Za-z0-9._-]{1,63}$' || fail "invalid target id: $target_id"
}

validate_target_root() {
  local target_root="$1"
  case "$target_root" in
    /*) ;;
    *) fail "target root is not absolute: $target_root" ;;
  esac
  [ -d "$target_root" ] || fail "target root does not exist: $target_root"
}

read_target_root_from_env() {
  local env_file="$1"
  [ -s "$env_file" ] || return 1
  local value
  value="$(sed -n 's/^TARGET_ROOT=//p' "$env_file" | sed -n '/./{p;q;}')"
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}

CMD="${1:-}"
SRC_REPO="${2:-$(pwd)}"
TARGET_ID="${3:-}"
TARGET_ROOT_INPUT="${4:-}"

TMP_DIR="$SRC_REPO/.tmp"
TARGET_POINTER_FILE="$TMP_DIR/rw-active-target-root.txt"
ACTIVE_TARGET_ID_FILE="$TMP_DIR/rw-active-target-id.txt"
TARGETS_DIR="$TMP_DIR/rw-targets"

mkdir -p "$TMP_DIR" "$TARGETS_DIR"

case "$CMD" in
  set-active)
    [ -n "$TARGET_ID" ] || fail "missing TARGET_ID"
    [ -n "$TARGET_ROOT_INPUT" ] || fail "missing TARGET_ROOT"
    validate_target_id "$TARGET_ID"
    TARGET_ROOT="$(normalize_target_root "$TARGET_ROOT_INPUT")"
    validate_target_root "$TARGET_ROOT"
    TARGET_ENV_FILE="$TARGETS_DIR/$TARGET_ID.env"
    {
      printf 'TARGET_ID=%s\n' "$TARGET_ID"
      printf 'TARGET_ROOT=%s\n' "$TARGET_ROOT"
      printf 'UPDATED_AT_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } > "$TARGET_ENV_FILE"
    printf '%s\n' "$TARGET_ID" > "$ACTIVE_TARGET_ID_FILE"
    printf '%s\n' "$TARGET_ROOT" > "$TARGET_POINTER_FILE"
    echo "RW_TARGET_SET_OK"
    echo "TARGET_ID=$TARGET_ID"
    echo "TARGET_ROOT=$TARGET_ROOT"
    ;;

  resolve-active)
    ACTIVE_ID="$(read_first_non_empty "$ACTIVE_TARGET_ID_FILE")"
    if [ -n "$ACTIVE_ID" ]; then
      TARGET_ENV_FILE="$TARGETS_DIR/$ACTIVE_ID.env"
      TARGET_ROOT="$(read_target_root_from_env "$TARGET_ENV_FILE" || true)"
      if [ -n "$TARGET_ROOT" ]; then
        TARGET_ROOT="$(normalize_target_root "$TARGET_ROOT")"
        validate_target_root "$TARGET_ROOT"
        printf '%s\n' "$TARGET_ROOT" > "$TARGET_POINTER_FILE"
        echo "RW_TARGET_RESOLVED_OK"
        echo "TARGET_ID=$ACTIVE_ID"
        echo "TARGET_ROOT=$TARGET_ROOT"
        exit 0
      fi
    fi

    RAW_TARGET="$(read_first_non_empty "$TARGET_POINTER_FILE")"
    if [ -n "$RAW_TARGET" ]; then
      TARGET_ROOT="$(normalize_target_root "$RAW_TARGET")"
      validate_target_root "$TARGET_ROOT"
      FALLBACK_ID="${ACTIVE_ID:-legacy-root-pointer}"
      if [ -z "${ACTIVE_ID:-}" ]; then
        printf '%s\n' "$FALLBACK_ID" > "$ACTIVE_TARGET_ID_FILE"
      fi
      echo "RW_TARGET_RESOLVED_OK"
      echo "TARGET_ID=$FALLBACK_ID"
      echo "TARGET_ROOT=$TARGET_ROOT"
      exit 0
    fi

    fail "RW_TARGET_RESOLVE_FAIL no active target id or root pointer"
    ;;

  *)
    fail "usage: $0 <set-active|resolve-active> [SRC_REPO] [TARGET_ID] [TARGET_ROOT]"
    ;;
esac
