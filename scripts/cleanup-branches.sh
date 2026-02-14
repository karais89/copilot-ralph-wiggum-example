#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="${BASE_BRANCH:-main}"
BRANCH_PREFIX="${BRANCH_PREFIX:-codex/}"
APPLY=0
DELETE_REMOTE=0

usage() {
  cat <<'EOF'
Usage:
  scripts/cleanup-branches.sh [--apply] [--delete-remote] [--base <branch>] [--prefix <prefix>]

Options:
  --apply           Actually delete merged local branches (default: dry-run)
  --delete-remote   Also delete merged remote branches in origin (requires --apply)
  --base <branch>   Base branch to compare merge status against (default: main)
  --prefix <prefix> Branch prefix to manage (default: codex/)
  -h, --help        Show this help

Environment:
  BASE_BRANCH, BRANCH_PREFIX can override defaults.

Examples:
  scripts/cleanup-branches.sh
  scripts/cleanup-branches.sh --apply
  scripts/cleanup-branches.sh --apply --delete-remote
  BASE_BRANCH=develop scripts/cleanup-branches.sh --apply
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --delete-remote)
      DELETE_REMOTE=1
      shift
      ;;
    --base)
      BASE_BRANCH="${2:-}"
      if [[ -z "$BASE_BRANCH" ]]; then
        echo "ERROR: --base requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --prefix)
      BRANCH_PREFIX="${2:-}"
      if [[ -z "$BRANCH_PREFIX" ]]; then
        echo "ERROR: --prefix requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$DELETE_REMOTE" -eq 1 && "$APPLY" -ne 1 ]]; then
  echo "ERROR: --delete-remote requires --apply" >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"

git fetch --prune origin >/dev/null 2>&1 || true

if git show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH"; then
  merge_ref="origin/$BASE_BRANCH"
elif git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
  merge_ref="$BASE_BRANCH"
else
  echo "ERROR: base branch not found locally or on origin: $BASE_BRANCH" >&2
  exit 1
fi

echo "Branch cleanup target"
echo "  base: $merge_ref"
echo "  prefix: $BRANCH_PREFIX"
echo "  current: $current_branch"
echo

local_prefixed=()
while IFS= read -r branch; do
  [[ -z "$branch" ]] && continue
  [[ "$branch" == "${BRANCH_PREFIX}"* ]] || continue
  local_prefixed+=("$branch")
done < <(git for-each-ref --format='%(refname:short)' refs/heads)

if [[ "${#local_prefixed[@]}" -eq 0 ]]; then
  echo "No local branches matched prefix: $BRANCH_PREFIX"
  exit 0
fi

merged_local=()
skipped_current=()
unmerged_local=()

for branch in "${local_prefixed[@]}"; do
  if [[ "$branch" == "$current_branch" ]]; then
    skipped_current+=("$branch")
    continue
  fi

  if git merge-base --is-ancestor "$branch" "$merge_ref"; then
    merged_local+=("$branch")
  else
    unmerged_local+=("$branch")
  fi
done

echo "Merged local branches (${#merged_local[@]}):"
if [[ "${#merged_local[@]}" -eq 0 ]]; then
  echo "  (none)"
else
  printf '  %s\n' "${merged_local[@]}"
fi
echo

echo "Unmerged local branches (${#unmerged_local[@]}):"
if [[ "${#unmerged_local[@]}" -eq 0 ]]; then
  echo "  (none)"
else
  printf '  %s\n' "${unmerged_local[@]}"
fi
echo

if [[ "${#skipped_current[@]}" -gt 0 ]]; then
  echo "Skipped current branch:"
  printf '  %s\n' "${skipped_current[@]}"
  echo
fi

if [[ "$APPLY" -ne 1 ]]; then
  echo "Dry-run only. Re-run with --apply to delete merged local branches."
  exit 0
fi

if [[ "${#merged_local[@]}" -eq 0 ]]; then
  echo "Nothing to delete."
  exit 0
fi

echo "Deleting merged local branches..."
for branch in "${merged_local[@]}"; do
  git branch -d "$branch"
done

if [[ "$DELETE_REMOTE" -eq 1 ]]; then
  echo
  echo "Deleting merged remote branches from origin when present..."
  for branch in "${merged_local[@]}"; do
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git push origin --delete "$branch"
    fi
  done
fi

echo
echo "Cleanup complete."
