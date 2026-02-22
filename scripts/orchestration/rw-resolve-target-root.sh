#!/usr/bin/env bash
set -euo pipefail

workspace_root="${1:-$(pwd)}"
workspace_root="$(cd "$workspace_root" && pwd -P)"

runtime_dir="$workspace_root/.ai/runtime"
active_id_file="$runtime_dir/rw-active-target-id.txt"
registry_dir="$runtime_dir/rw-targets"
pointer_file="$runtime_dir/rw-active-target-root.txt"

mkdir -p "$registry_dir"

read_first_nonempty() {
  local file="$1"
  [ -f "$file" ] || return 1
  sed -n '/./{p;q;}' "$file"
}

target_id=""
raw_target=""

if target_id="$(read_first_nonempty "$active_id_file" 2>/dev/null || true)"; then
  :
fi

if [ -n "$target_id" ] && [ -f "$registry_dir/$target_id.env" ]; then
  raw_target="$(sed -n 's/^TARGET_ROOT=//p' "$registry_dir/$target_id.env" | sed -n '/./{p;q;}')"
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
  printf '%s\n' "$target_id" > "$active_id_file"
  printf 'TARGET_ID=%s\nTARGET_ROOT=%s\n' "$target_id" "$raw_target" > "$registry_dir/workspace-root.env"
  printf '%s\n' "$raw_target" > "$pointer_file"
fi

case "$raw_target" in
  /*) ;;
  *)
    echo "RW_TARGET_ROOT_INVALID" >&2
    echo "resolver produced non-absolute TARGET_ROOT: $raw_target" >&2
    exit 2
    ;;
esac

echo "TARGET_ACTIVE_ID_FILE=$active_id_file"
echo "TARGET_REGISTRY_DIR=$registry_dir"
echo "TARGET_POINTER_FILE=$pointer_file"
echo "TARGET_ID=$target_id"
echo "RAW_TARGET=$raw_target"
echo "TARGET_ROOT=$raw_target"
