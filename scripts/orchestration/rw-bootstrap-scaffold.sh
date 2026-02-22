#!/usr/bin/env bash
set -euo pipefail

workspace_root="${1:-$(pwd)}"
workspace_root="$(cd "$workspace_root" && pwd -P)"
doc_lang="${RW_DOC_LANG:-ko}"

ai_root="$workspace_root/.ai"
tasks_dir="$ai_root/tasks"
notes_dir="$ai_root/notes"
archive_dir="$ai_root/progress-archive"
runtime_dir="$ai_root/runtime"
targets_dir="$runtime_dir/rw-targets"
features_dir="$ai_root/features"
templates_dir="$ai_root/templates"

mkdir -p "$tasks_dir" "$notes_dir" "$archive_dir" "$runtime_dir" "$targets_dir" "$features_dir" "$templates_dir"

case "$doc_lang" in
  ko|en)
    ;;
  *)
    echo "RW_DOC_LANG must be one of: ko, en"
    exit 1
    ;;
esac

if [ "$doc_lang" = "en" ]; then
  doc_lang_line='- User document language (`.ai/*` docs): English by default'
else
  doc_lang_line='- User document language (`.ai/*` docs): Korean by default'
fi

target_id="workspace-root"
active_id_file="$runtime_dir/rw-active-target-id.txt"
pointer_file="$runtime_dir/rw-active-target-root.txt"
target_env_file="$targets_dir/workspace-root.env"

printf '%s\n' "$target_id" > "$active_id_file"
printf '%s\n' "$workspace_root" > "$pointer_file"
printf 'TARGET_ID=%s\nTARGET_ROOT=%s\n' "$target_id" "$workspace_root" > "$target_env_file"

if [ ! -f "$ai_root/CONTEXT.md" ]; then
  if [ -f "$templates_dir/CONTEXT-BOOTSTRAP.md" ]; then
    cp "$templates_dir/CONTEXT-BOOTSTRAP.md" "$ai_root/CONTEXT.md"
  else
    cat > "$ai_root/CONTEXT.md" <<EOF
# Workspace Context

## Language Policy
- Prompt body language (`.github/prompts/rw-*.prompt.md`): English (required)
$doc_lang_line
- Commit message language: English (Conventional Commits)

## Machine-Parsed Tokens (Do Not Translate)
- `Task Status`, `Log`
- `pending`, `in-progress`, `completed`
- `LANG_POLICY_MISSING`

## Prompt Authoring Rules
- Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first via Step 0
EOF
  fi
fi

# Keep language policy line aligned with RW_DOC_LANG even when template was copied.
context_tmp_file="$(mktemp "${TMPDIR:-/tmp}/rw-context-XXXXXX")"
awk -v desired="$doc_lang_line" '
  BEGIN { replaced = 0 }
  /^- User document language/ {
    print desired
    replaced = 1
    next
  }
  { print }
  END {
    if (!replaced) {
      print desired
    }
  }
' "$ai_root/CONTEXT.md" > "$context_tmp_file"
mv "$context_tmp_file" "$ai_root/CONTEXT.md"

if [ ! -f "$ai_root/PLAN.md" ]; then
  cat > "$ai_root/PLAN.md" <<'EOF'
# Workspace

## Overview
- Project purpose is undecided (user input required).
- Technology stack is undecided.
- Next step: run rw-new-project, then run rw-plan and rw-run.

## Feature Notes (append-only)
EOF
fi

if ! grep -Fq "## Feature Notes (append-only)" "$ai_root/PLAN.md"; then
  printf '\n## Feature Notes (append-only)\n' >> "$ai_root/PLAN.md"
fi

if ! ls "$tasks_dir"/TASK-*.md >/dev/null 2>&1; then
  cat > "$tasks_dir/TASK-01-bootstrap-workspace.md" <<'EOF'
# TASK-01: bootstrap-workspace

## Dependencies
- none

## Description
- Ensure the RW workspace baseline files and folders exist.

## Acceptance Criteria
- `.ai/PLAN.md` and `.ai/PROGRESS.md` exist.
- target pointer files exist under `.ai/runtime/`.

## Files to Create/Modify
- .ai/PLAN.md
- .ai/PROGRESS.md
- .ai/runtime/rw-active-target-id.txt
- .ai/runtime/rw-targets/workspace-root.env
- .ai/runtime/rw-active-target-root.txt

## Verification
- test -f .ai/PLAN.md
- test -f .ai/PROGRESS.md
EOF
fi

if [ ! -f "$ai_root/PROGRESS.md" ]; then
  {
    printf '# Progress\n\n'
    printf '## Task Status\n'
    printf '| Task | Title | Status | Commit |\n'
    printf '|------|-------|--------|--------|\n'
    for task_file in "$tasks_dir"/TASK-*.md; do
      [ -f "$task_file" ] || continue
      task_id="$(basename "$task_file" | sed -E 's/^(TASK-[0-9]+).*/\1/')"
      title="$(sed -En '1{s/^# TASK-[0-9]+: *//;p;}' "$task_file")"
      [ -n "$title" ] || title="$(basename "$task_file" .md)"
      printf '| %s | %s | pending | - |\n' "$task_id" "$title"
    done
    printf '\n## Log\n'
    printf -- '- **%s** — Initial workspace scaffolded by rw-bootstrap-scaffold.\n' "$(date +%Y-%m-%d)"
  } > "$ai_root/PROGRESS.md"
fi

echo "SCAFFOLD_ROOT=$workspace_root"
echo "SCAFFOLD_PLAN=$ai_root/PLAN.md"
echo "SCAFFOLD_PROGRESS=$ai_root/PROGRESS.md"
echo "SCAFFOLD_TASK01=$tasks_dir/TASK-01-bootstrap-workspace.md"
echo "SCAFFOLD_TARGET_ID_FILE=$active_id_file"
echo "SCAFFOLD_TARGET_ENV_FILE=$target_env_file"
echo "SCAFFOLD_TARGET_POINTER_FILE=$pointer_file"
echo "SCAFFOLD_DOC_LANG=$doc_lang"
