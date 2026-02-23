#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

read_first_nonempty() {
  local file="$1"
  [ -f "$file" ] || return 1
  sed -n '/./{p;q;}' "$file"
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
  sed -n 's/^TARGET_ROOT=//p' "$env_file" | sed -n '/./{p;q;}'
}

write_registry_entry() {
  local env_file="$1"
  local target_id="$2"
  local target_root="$3"
  {
    printf 'TARGET_ID=%s\n' "$target_id"
    printf 'TARGET_ROOT=%s\n' "$target_root"
    printf 'UPDATED_AT_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$env_file"
}

print_resolve_output() {
  local active_id_file="$1"
  local registry_dir="$2"
  local pointer_file="$3"
  local target_id="$4"
  local target_root="$5"

  echo "TARGET_ACTIVE_ID_FILE=$active_id_file"
  echo "TARGET_REGISTRY_DIR=$registry_dir"
  echo "TARGET_POINTER_FILE=$pointer_file"
  echo "TARGET_ID=$target_id"
  echo "RAW_TARGET=$target_root"
  echo "TARGET_ROOT=$target_root"
}

resolve_active() {
  local workspace_root="$1"
  workspace_root="$(cd "$workspace_root" && pwd -P)"

  local runtime_dir="$workspace_root/.ai/runtime"
  local active_id_file="$runtime_dir/rw-active-target-id.txt"
  local registry_dir="$runtime_dir/rw-targets"
  local pointer_file="$runtime_dir/rw-active-target-root.txt"

  mkdir -p "$registry_dir"

  local target_id=""
  local raw_target=""

  target_id="$(read_first_nonempty "$active_id_file" 2>/dev/null || true)"

  if [ -n "$target_id" ] && [ -f "$registry_dir/$target_id.env" ]; then
    raw_target="$(read_target_root_from_env "$registry_dir/$target_id.env" || true)"
  fi

  if [ -z "$raw_target" ]; then
    raw_target="$(read_first_nonempty "$pointer_file" 2>/dev/null || true)"
    if [ -n "$raw_target" ]; then
      target_id="legacy-root-pointer"
    fi
  fi

  if [ -z "$raw_target" ]; then
    target_id="workspace-root"
    raw_target="$workspace_root"
  fi

  validate_target_root "$raw_target"
  validate_target_id "$target_id"

  write_registry_entry "$registry_dir/$target_id.env" "$target_id" "$raw_target"
  printf '%s\n' "$target_id" > "$active_id_file"
  printf '%s\n' "$raw_target" > "$pointer_file"

  print_resolve_output "$active_id_file" "$registry_dir" "$pointer_file" "$target_id" "$raw_target"
}

set_active() {
  local workspace_root="$1"
  local target_id="$2"
  local target_root="$3"

  workspace_root="$(cd "$workspace_root" && pwd -P)"
  target_root="$(cd "$target_root" && pwd -P)"

  validate_target_id "$target_id"
  validate_target_root "$target_root"

  local runtime_dir="$workspace_root/.ai/runtime"
  local active_id_file="$runtime_dir/rw-active-target-id.txt"
  local registry_dir="$runtime_dir/rw-targets"
  local pointer_file="$runtime_dir/rw-active-target-root.txt"
  local env_file="$registry_dir/$target_id.env"

  mkdir -p "$registry_dir"

  write_registry_entry "$env_file" "$target_id" "$target_root"
  printf '%s\n' "$target_id" > "$active_id_file"
  printf '%s\n' "$target_root" > "$pointer_file"

  echo "RW_TARGET_SET_OK"
  print_resolve_output "$active_id_file" "$registry_dir" "$pointer_file" "$target_id" "$target_root"
}

cmd="${1:-resolve-active}"

case "$cmd" in
  resolve-active)
    workspace_root="${2:-$(pwd)}"
    resolve_active "$workspace_root"
    ;;
  set-active)
    workspace_root="${2:-$(pwd)}"
    target_id="${3:-}"
    target_root="${4:-}"
    [ -n "$target_id" ] || fail "missing TARGET_ID"
    [ -n "$target_root" ] || fail "missing TARGET_ROOT"
    set_active "$workspace_root" "$target_id" "$target_root"
    ;;
  -h|--help)
    cat <<'EOF'
Usage:
  rw-resolve-target-root.sh [resolve-active] [workspace-root]
  rw-resolve-target-root.sh set-active [workspace-root] <target-id> <absolute-target-root>
EOF
    ;;
  *)
    # Backward-compatible form: first positional argument is workspace root.
    resolve_active "$cmd"
    ;;
esac
