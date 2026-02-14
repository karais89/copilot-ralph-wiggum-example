#!/usr/bin/env bash
#
# rw-smoke-test.sh
#
# Automated smoke test for the Ralph Wiggum orchestration workflow.
# Tests file contracts, state transitions, and token conventions
# without requiring runSubagent (Copilot-specific).
#
# Usage:
#   ./scripts/rw-smoke-test.sh
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$REPO_ROOT/test/smoke/fixtures"
ASSERTIONS="$REPO_ROOT/test/smoke/assertions.sh"

# shellcheck source=../test/smoke/assertions.sh
source "$ASSERTIONS"

# Use a unique temp dir per run
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rw-smoke-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M)
CURRENT_STAGE="startup"
SMOKE_TOTAL_PHASES=8
SMOKE_EXPECTED_DISPATCHES=10
TARGET_ROOT=""
RESULT_DIR=""
RESULT_JSON=""
RESULT_MD=""
CHECK_BUILD_STATUS="SKIPPED"
CHECK_BUILD_DETAIL="not-run"
CHECK_GREET_STATUS="SKIPPED"
CHECK_GREET_DETAIL="not-run"
CHECK_GOODBYE_STATUS="SKIPPED"
CHECK_GOODBYE_DETAIL="not-run"
CHECK_TEST_STATUS="SKIPPED"
CHECK_TEST_DETAIL="not-run"

set_stage() {
  CURRENT_STAGE="$1"
  echo ""
  echo "  --- $1 ---"
}

inplace_replace() {
  local expr="$1"
  local file="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i -e "$expr" "$file"
  else
    sed -i '' -e "$expr" "$file"
  fi
}

insert_task04_pending_row() {
  local progress_file="$1"
  local tmp_file
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/rw-smoke-progress-XXXXXX")"
  awk '
    { print }
    /^\| TASK-03 / { print "| TASK-04 | goodbye 명령 추가 | pending | - |" }
  ' "$progress_file" > "$tmp_file"
  mv "$tmp_file" "$progress_file"
}

replace_task04_completed_row() {
  local progress_file="$1"
  local task_sha="$2"
  local tmp_file
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/rw-smoke-progress-XXXXXX")"
  awk -v sha="$task_sha" '
    /^\| TASK-04 \|/ { print "| TASK-04 | goodbye 명령 추가 | completed | " sha " |"; next }
    { print }
  ' "$progress_file" > "$tmp_file"
  mv "$tmp_file" "$progress_file"
}

has_npm_test_script() {
  local package_json="$1"
  if [ ! -f "$package_json" ]; then
    return 1
  fi
  python3 - "$package_json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
scripts = data.get("scripts", {})
test_script = scripts.get("test", "")
if isinstance(test_script, str) and test_script and test_script != "echo \"Error: no test specified\" && exit 1":
    sys.exit(0)
sys.exit(1)
PY
}

write_smoke_result_artifacts() {
  local status="$1"
  local failed_phase="${2:-null}"
  local reason="${3:-null}"
  local git_head="null"
  local safe_failed_phase="$failed_phase"
  local safe_reason="$reason"

  if [ -z "$RESULT_DIR" ] || [ -z "$RESULT_JSON" ] || [ -z "$RESULT_MD" ]; then
    return 0
  fi

  mkdir -p "$RESULT_DIR"
  if [ -d "$TARGET_ROOT/.git" ]; then
    git_head="$(cd "$TARGET_ROOT" && git rev-parse --short HEAD 2>/dev/null || true)"
    if [ -z "$git_head" ]; then
      git_head="null"
    fi
  fi

  if [ -z "$safe_failed_phase" ]; then
    safe_failed_phase="null"
  fi
  if [ -z "$safe_reason" ]; then
    safe_reason="null"
  fi

  STATUS="$status" \
  TARGET_ROOT="$TARGET_ROOT" \
  GIT_HEAD="$git_head" \
  TOTAL_PHASES="$SMOKE_TOTAL_PHASES" \
  DISPATCHES="$SMOKE_EXPECTED_DISPATCHES" \
  FAILED_PHASE="$safe_failed_phase" \
  REASON="$safe_reason" \
  CHECK_BUILD_STATUS="$CHECK_BUILD_STATUS" \
  CHECK_BUILD_DETAIL="$CHECK_BUILD_DETAIL" \
  CHECK_GREET_STATUS="$CHECK_GREET_STATUS" \
  CHECK_GREET_DETAIL="$CHECK_GREET_DETAIL" \
  CHECK_GOODBYE_STATUS="$CHECK_GOODBYE_STATUS" \
  CHECK_GOODBYE_DETAIL="$CHECK_GOODBYE_DETAIL" \
  CHECK_TEST_STATUS="$CHECK_TEST_STATUS" \
  CHECK_TEST_DETAIL="$CHECK_TEST_DETAIL" \
  RESULT_JSON="$RESULT_JSON" \
  python3 - <<'PY'
import datetime as dt
import json
import os

def to_optional(v):
    return None if v in ("", "null", None) else v

payload = {
    "status": os.environ["STATUS"],
    "timestamp": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_root": os.environ.get("TARGET_ROOT", ""),
    "git_head": to_optional(os.environ.get("GIT_HEAD", "null")),
    "total_phases": int(os.environ.get("TOTAL_PHASES", "0")),
    "dispatches": int(os.environ.get("DISPATCHES", "0")),
    "failed_phase": to_optional(os.environ.get("FAILED_PHASE", "null")),
    "reason": to_optional(os.environ.get("REASON", "null")),
    "checks": {
        "build": {
            "status": os.environ.get("CHECK_BUILD_STATUS", "SKIPPED"),
            "detail": os.environ.get("CHECK_BUILD_DETAIL", "not-run"),
        },
        "greet": {
            "status": os.environ.get("CHECK_GREET_STATUS", "SKIPPED"),
            "detail": os.environ.get("CHECK_GREET_DETAIL", "not-run"),
        },
        "goodbye": {
            "status": os.environ.get("CHECK_GOODBYE_STATUS", "SKIPPED"),
            "detail": os.environ.get("CHECK_GOODBYE_DETAIL", "not-run"),
        },
        "test": {
            "status": os.environ.get("CHECK_TEST_STATUS", "SKIPPED"),
            "detail": os.environ.get("CHECK_TEST_DETAIL", "not-run"),
        },
    },
}

with open(os.environ["RESULT_JSON"], "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

  cat > "$RESULT_MD" <<EOF
# RW Smoke Result

- Status: $status
- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Target Root: $TARGET_ROOT
- Git Head: $git_head
- Total Phases: $SMOKE_TOTAL_PHASES
- Dispatches: $SMOKE_EXPECTED_DISPATCHES
- Failed Phase: $safe_failed_phase
- Reason: $safe_reason

## Checks
- Build: $CHECK_BUILD_STATUS ($CHECK_BUILD_DETAIL)
- Greet: $CHECK_GREET_STATUS ($CHECK_GREET_DETAIL)
- Goodbye: $CHECK_GOODBYE_STATUS ($CHECK_GOODBYE_DETAIL)
- Test: $CHECK_TEST_STATUS ($CHECK_TEST_DETAIL)
EOF
}

on_unexpected_error() {
  local exit_code="${1:-1}"
  local line_no="${2:-unknown}"
  trap - ERR
  if [ -n "$TARGET_ROOT" ]; then
    write_smoke_result_artifacts "FAIL" "$CURRENT_STAGE" "line=$line_no exit=$exit_code"
  fi
  assert_fail "stage failed: $CURRENT_STAGE" "line=$line_no exit=$exit_code"
  echo "  Stage failure: $CURRENT_STAGE (line $line_no, exit $exit_code)"
  echo ""
  print_summary || true
  exit 1
}

trap 'on_unexpected_error $? $LINENO' ERR

echo "=== RW Smoke Test ==="
echo "Test dir: $TEST_DIR"
echo ""

# ============================================================
# Scenario 1: New Project Flow
# ============================================================
echo "[Scenario 1: New Project Flow]"
S1="$TEST_DIR/scenario1"
TARGET_ROOT="$S1"
RESULT_DIR="$TARGET_ROOT/.ai/runtime/smoke"
RESULT_JSON="$RESULT_DIR/last-result.json"
RESULT_MD="$RESULT_DIR/last-result.md"

# --- Step 1: Extract ---
set_stage "extract"
"$REPO_ROOT/scripts/extract-template.sh" "$S1" >/dev/null 2>&1

assert_file_exists "$S1/.github/prompts/rw-init.prompt.md" "rw-init.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-new-project.prompt.md" "rw-new-project.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-onboard-project.prompt.md" "rw-onboard-project.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-doctor.prompt.md" "rw-doctor.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-feature.prompt.md" "rw-feature.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-plan.prompt.md" "rw-plan.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-run.prompt.md" "rw-run.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-review.prompt.md" "rw-review.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-archive.prompt.md" "rw-archive.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/rw-smoke-test.prompt.md" "rw-smoke-test.prompt.md extracted"
assert_file_exists "$S1/.github/prompts/RW-INTERACTIVE-POLICY.md" "RW-INTERACTIVE-POLICY.md extracted"
assert_file_exists "$S1/.github/prompts/RW-TARGET-ROOT-RESOLUTION.md" "RW-TARGET-ROOT-RESOLUTION.md extracted"
assert_dir_exists "$S1/.github/prompts/smoke" "smoke prompt module directory extracted"
assert_file_exists "$S1/.github/prompts/smoke/SMOKE-CONTRACT.md" "SMOKE-CONTRACT.md extracted"
assert_file_exists "$S1/.github/prompts/smoke/phases/phase-01-new-project.md" "smoke phase-01 extracted"
assert_file_exists "$S1/.github/prompts/smoke/templates/run-task.subagent.md" "smoke run-task template extracted"
assert_file_exists "$S1/scripts/rw-resolve-target-root.sh" "rw-resolve-target-root.sh extracted"
assert_file_exists "$S1/scripts/rw-bootstrap-scaffold.sh" "rw-bootstrap-scaffold.sh extracted"
assert_file_exists "$S1/scripts/rw-target-registry.sh" "rw-target-registry.sh extracted"
assert_file_exists "$S1/scripts/rw" "rw helper script extracted"
assert_file_exists "$S1/scripts/validate-smoke-result.sh" "validate-smoke-result.sh extracted"
assert_file_exists "$S1/scripts/check-prompts.mjs" "check-prompts.mjs extracted"
assert_file_exists "$S1/.ai/CONTEXT.md" "CONTEXT.md extracted"
assert_file_exists "$S1/.ai/GUIDE.md" "GUIDE.md extracted"
assert_file_exists "$S1/.ai/features/FEATURE-TEMPLATE.md" "FEATURE-TEMPLATE.md extracted"
assert_file_exists "$S1/.ai/features/README.md" "features README extracted"
assert_file_exists "$S1/.ai/templates/CONTEXT-BOOTSTRAP.md" "CONTEXT-BOOTSTRAP.md extracted"
assert_file_exists "$S1/.ai/templates/PROJECT-CHARTER-TEMPLATE.md" "PROJECT-CHARTER-TEMPLATE.md extracted"
assert_file_exists "$S1/.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md" "BOOTSTRAP-FEATURE-TEMPLATE.md extracted"
assert_file_exists "$S1/.ai/templates/SMOKE-RESULT-SCHEMA.json" "SMOKE-RESULT-SCHEMA.json extracted"
assert_command_succeeds "prompt integrity check passes" bash -c "cd '$S1' && node scripts/check-prompts.mjs >/dev/null 2>&1"
assert_command_succeeds "rw helper next works pre-scaffold" bash -c "cd '$S1' && ./scripts/rw next >/dev/null 2>&1"
assert_command_succeeds "rw helper run alias resolves prompt" bash -c "cd '$S1' && ./scripts/rw run >/dev/null 2>&1"

# --- Step 2: Scaffold ---
set_stage "scaffold"
(cd "$S1" && git init -q && git add -A && git commit -q -m "chore: initial extract")
"$S1/scripts/rw-bootstrap-scaffold.sh" "$S1" >/dev/null 2>&1

assert_file_exists "$S1/.ai/PLAN.md" "PLAN.md created"
assert_file_exists "$S1/.ai/PROGRESS.md" "PROGRESS.md created"
assert_file_exists "$S1/.ai/tasks/TASK-01-bootstrap-workspace.md" "TASK-01 created"
assert_file_exists "$S1/.ai/runtime/rw-active-target-id.txt" "target-id pointer created"
assert_file_exists "$S1/.ai/runtime/rw-active-target-root.txt" "target-root pointer created"
assert_file_exists "$S1/.ai/runtime/rw-targets/workspace-root.env" "target env created"
assert_file_contains "$S1/.ai/runtime/rw-active-target-id.txt" "workspace-root" "target-id is workspace-root"
assert_file_contains "$S1/.ai/PROGRESS.md" "## Task Status" "PROGRESS has Task Status section"
assert_file_contains "$S1/.ai/PROGRESS.md" "## Log" "PROGRESS has Log section"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-01" "pending" 

# --- Step 3: rw-new-project (simulated) ---
set_stage "rw-new-project (sim)"
cp "$FIXTURES/scenario1/PLAN-after-new-project.md" "$S1/.ai/PLAN.md"
cp "$FIXTURES/scenario1/PROJECT-CHARTER.md" "$S1/.ai/notes/PROJECT-CHARTER-${TIMESTAMP}.md"
cp "$FIXTURES/scenario1/bootstrap-feature.md" "$S1/.ai/features/${TIMESTAMP}-bootstrap-foundation.md"
(cd "$S1" && git add -A && git commit -q -m "feat: rw-new-project simulation")

FEATURE_FILE="$S1/.ai/features/${TIMESTAMP}-bootstrap-foundation.md"
assert_file_contains "$S1/.ai/PLAN.md" "## Feature Notes (append-only)" "PLAN has Feature Notes section"
assert_file_contains "$S1/.ai/PLAN.md" "Hello CLI" "PLAN has project overview"
assert_file_exists "$S1/.ai/notes/PROJECT-CHARTER-${TIMESTAMP}.md" "PROJECT-CHARTER created"
assert_file_exists "$FEATURE_FILE" "bootstrap feature file created"
assert_feature_status "$FEATURE_FILE" "READY_FOR_PLAN"
assert_file_contains "$FEATURE_FILE" "Planning Profile: FAST_TEST" "feature has FAST_TEST profile"

# --- Step 4: rw-plan (simulated) ---
set_stage "rw-plan (sim)"
cp "$FIXTURES/scenario1/TASK-02-init-project.md" "$S1/.ai/tasks/"
cp "$FIXTURES/scenario1/TASK-03-cli-greet.md" "$S1/.ai/tasks/"

# Update PLAN Feature Notes
cat >> "$S1/.ai/PLAN.md" <<EOF
- $TODAY: [bootstrap-foundation] Hello CLI 기초 구조. Related tasks: TASK-02~TASK-03.
EOF

# Update PROGRESS
cat > "$S1/.ai/PROGRESS.md" <<EOF
# Progress

## Task Status
| Task | Title | Status | Commit |
|------|-------|--------|--------|
| TASK-01 | 워크스페이스 부트스트랩 | pending | - |
| TASK-02 | 프로젝트 초기화 | pending | - |
| TASK-03 | CLI greet 명령 | pending | - |

## Log
- **$TODAY** — Initial workspace scaffolded by rw-bootstrap-scaffold.
- **$TODAY** — Added feature planning tasks TASK-02~TASK-03 for [bootstrap-foundation].
EOF

# Update feature status
inplace_replace 's/Status: READY_FOR_PLAN/Status: PLANNED/' "$FEATURE_FILE"

(cd "$S1" && git add -A && git commit -q -m "feat: rw-plan simulation")

assert_file_exists "$S1/.ai/tasks/TASK-02-init-project.md" "TASK-02 created"
assert_file_exists "$S1/.ai/tasks/TASK-03-cli-greet.md" "TASK-03 created"
assert_file_count "$S1/.ai/tasks" "TASK-*.md" 3 3 "3 task files exist"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-02" "pending"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-03" "pending"
assert_file_contains "$S1/.ai/PLAN.md" "bootstrap-foundation" "Feature Notes appended"
assert_feature_status "$FEATURE_FILE" "PLANNED"
assert_progress_log_contains "$S1/.ai/PROGRESS.md" "TASK-02~TASK-03"

# --- Step 5: rw-run (simulated) ---
set_stage "rw-run (sim)"

# TASK-01: already done by scaffold
TASK01_SHA=$(cd "$S1" && git rev-parse --short HEAD)

# TASK-02: install project
cp "$FIXTURES/scenario1/code/package.json" "$S1/"
cp "$FIXTURES/scenario1/code/tsconfig.json" "$S1/"
cat > "$S1/.gitignore" <<'GITIGNORE'
node_modules/
dist/
GITIGNORE
(cd "$S1" && npm install --silent 2>/dev/null)
(cd "$S1" && git add -A && git commit -q -m "feat(init): initialize Node.js + TypeScript project")
TASK02_SHA=$(cd "$S1" && git rev-parse --short HEAD)

# TASK-03: implement greet
mkdir -p "$S1/src"
cp "$FIXTURES/scenario1/code/src/index.ts" "$S1/src/"
(cd "$S1" && npm run build --silent 2>/dev/null)
(cd "$S1" && git add -A && git commit -q -m "feat(cli): implement greet command")
TASK03_SHA=$(cd "$S1" && git rev-parse --short HEAD)

# Update PROGRESS
cat > "$S1/.ai/PROGRESS.md" <<EOF
# Progress

## Task Status
| Task | Title | Status | Commit |
|------|-------|--------|--------|
| TASK-01 | 워크스페이스 부트스트랩 | completed | $TASK01_SHA |
| TASK-02 | 프로젝트 초기화 | completed | $TASK02_SHA |
| TASK-03 | CLI greet 명령 | completed | $TASK03_SHA |

## Log
- **$TODAY** — Initial workspace scaffolded by rw-bootstrap-scaffold.
- **$TODAY** — Added feature planning tasks TASK-02~TASK-03 for [bootstrap-foundation].
- **$TODAY** — TASK-01 completed: 워크스페이스 부트스트랩 검증 완료.
- **$TODAY** — TASK-02 completed: Node.js+TypeScript 프로젝트 초기화.
- **$TODAY** — TASK-03 completed: greet 명령 구현 완료.
EOF
(cd "$S1" && git add -A && git commit -q -m "chore(progress): all tasks completed")

assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-01" "completed"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-02" "completed"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-03" "completed"
assert_command_succeeds "npm run build succeeds" bash -c "cd '$S1' && npm run build --silent 2>/dev/null"
assert_command_output_contains "greet outputs Hello, World!" "Hello, World!" bash -c "cd '$S1' && node dist/index.js greet World"
assert_progress_log_contains "$S1/.ai/PROGRESS.md" "TASK-03 completed"

# --- Step 6: rw-review (simulated) ---
set_stage "rw-review (sim)"

# Run verification commands from task files (acceptance criteria check)
REVIEW_OK_COUNT=0

# TASK-01 verification
if [ -f "$S1/.ai/PLAN.md" ] && [ -f "$S1/.ai/PROGRESS.md" ]; then
  ((REVIEW_OK_COUNT++)) || true
fi

# TASK-02 verification
if (cd "$S1" && npm install --silent 2>/dev/null && npx tsc --version >/dev/null 2>&1); then
  ((REVIEW_OK_COUNT++)) || true
fi

# TASK-03 verification
GREET_OUTPUT=$(cd "$S1" && node dist/index.js greet World 2>&1)
if [ "$GREET_OUTPUT" = "Hello, World!" ]; then
  ((REVIEW_OK_COUNT++)) || true
fi

# Write REVIEW_OK to PROGRESS
cat >> "$S1/.ai/PROGRESS.md" <<EOF
- **$TODAY** — REVIEW_OK TASK-01: verification passed
- **$TODAY** — REVIEW_OK TASK-02: verification passed
- **$TODAY** — REVIEW_OK TASK-03: verification passed
EOF
(cd "$S1" && git add -A && git commit -q -m "chore(review): all tasks REVIEW_OK")

assert_progress_log_contains "$S1/.ai/PROGRESS.md" "REVIEW_OK TASK-01"
assert_progress_log_contains "$S1/.ai/PROGRESS.md" "REVIEW_OK TASK-02"
assert_progress_log_contains "$S1/.ai/PROGRESS.md" "REVIEW_OK TASK-03"
assert_file_not_contains "$S1/.ai/PROGRESS.md" "REVIEW_FAIL" "no REVIEW_FAIL in PROGRESS"
if [ "$REVIEW_OK_COUNT" -eq 3 ]; then
  assert_pass "all 3 tasks passed verification (REVIEW_OK count=$REVIEW_OK_COUNT)"
else
  assert_fail "expected 3 REVIEW_OK, got $REVIEW_OK_COUNT"
fi
assert_git_commit_count "$S1" 7 "Scenario 1 commit count is 7"

# ============================================================
# Scenario 2: Feature Addition Flow
# ============================================================
echo ""
echo "[Scenario 2: Feature Addition Flow]"

# --- Step 7: rw-feature (simulated) ---
set_stage "rw-feature (sim)"
cp "$FIXTURES/scenario2/add-goodbye-feature.md" "$S1/.ai/features/${TIMESTAMP}-add-goodbye-command.md"
FEATURE2_FILE="$S1/.ai/features/${TIMESTAMP}-add-goodbye-command.md"

assert_file_exists "$FEATURE2_FILE" "goodbye feature file created"
assert_feature_status "$FEATURE2_FILE" "READY_FOR_PLAN"
assert_file_contains "$FEATURE2_FILE" "Planning Profile: FAST_TEST" "feature has FAST_TEST profile"

# --- Step 8: rw-plan (simulated, feature 2) ---
set_stage "rw-plan (sim)"
cp "$FIXTURES/scenario2/TASK-04-goodbye-command.md" "$S1/.ai/tasks/"

# Append Feature Notes
cat >> "$S1/.ai/PLAN.md" <<EOF
- $TODAY: [add-goodbye-command] goodbye 명령 추가. Related tasks: TASK-04.
EOF

# Add TASK-04 to PROGRESS
insert_task04_pending_row "$S1/.ai/PROGRESS.md"

# Add log entry
cat >> "$S1/.ai/PROGRESS.md" <<EOF
- **$TODAY** — Added feature planning tasks TASK-04 for [add-goodbye-command].
EOF

# Update feature status
inplace_replace 's/Status: READY_FOR_PLAN/Status: PLANNED/' "$FEATURE2_FILE"

(cd "$S1" && git add -A && git commit -q -m "feat: rw-plan simulation — TASK-04 for goodbye")

assert_file_exists "$S1/.ai/tasks/TASK-04-goodbye-command.md" "TASK-04 created"
assert_file_count "$S1/.ai/tasks" "TASK-*.md" 4 4 "4 task files exist"
assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-04" "pending"
assert_file_contains "$S1/.ai/PLAN.md" "add-goodbye-command" "Feature Notes appended for goodbye"
assert_feature_status "$FEATURE2_FILE" "PLANNED"

# --- Step 9: rw-run (simulated, TASK-04) ---
set_stage "rw-run (sim)"
cp "$FIXTURES/scenario2/code/src/index.ts" "$S1/src/"
(cd "$S1" && npm run build --silent 2>/dev/null)
(cd "$S1" && git add -A && git commit -q -m "feat(cli): implement goodbye command")
TASK04_SHA=$(cd "$S1" && git rev-parse --short HEAD)

# Update PROGRESS for TASK-04
replace_task04_completed_row "$S1/.ai/PROGRESS.md" "$TASK04_SHA"
cat >> "$S1/.ai/PROGRESS.md" <<EOF
- **$TODAY** — TASK-04 completed: goodbye 명령 구현 완료.
EOF
(cd "$S1" && git add -A && git commit -q -m "chore(progress): TASK-04 completed")

assert_progress_status "$S1/.ai/PROGRESS.md" "TASK-04" "completed"
assert_command_succeeds "npm run build succeeds after goodbye" bash -c "cd '$S1' && npm run build --silent 2>/dev/null"
assert_command_output_contains "goodbye outputs Goodbye, World!" "Goodbye, World!" bash -c "cd '$S1' && node dist/index.js goodbye World"
assert_command_output_contains "greet still works" "Hello, World!" bash -c "cd '$S1' && node dist/index.js greet World"
assert_progress_log_contains "$S1/.ai/PROGRESS.md" "TASK-04 completed"

# --- Step 10: rw-review (simulated, TASK-04) ---
set_stage "rw-review (sim)"

GOODBYE_OUTPUT=$(cd "$S1" && node dist/index.js goodbye World 2>&1)
GREET_OUTPUT2=$(cd "$S1" && node dist/index.js greet World 2>&1)

if [ "$GOODBYE_OUTPUT" = "Goodbye, World!" ] && [ "$GREET_OUTPUT2" = "Hello, World!" ]; then
  cat >> "$S1/.ai/PROGRESS.md" <<EOF
- **$TODAY** — REVIEW_OK TASK-04: verification passed
EOF
  assert_pass "TASK-04 passes verification"
else
  assert_fail "TASK-04 verification" "goodbye=$GOODBYE_OUTPUT greet=$GREET_OUTPUT2"
fi
(cd "$S1" && git add -A && git commit -q -m "chore(review): TASK-04 REVIEW_OK")

assert_progress_log_contains "$S1/.ai/PROGRESS.md" "REVIEW_OK TASK-04"
assert_file_not_contains "$S1/.ai/PROGRESS.md" "REVIEW_FAIL" "no REVIEW_FAIL in final PROGRESS"
assert_git_commit_count "$S1" 11 "Final commit count is 11"

# ============================================================
# Scenario 3: Existing Project Onboarding Flow
# ============================================================
echo ""
echo "[Scenario 3: Existing Project Onboarding Flow]"
S3="$TEST_DIR/scenario3"

# --- Step 11: Extract ---
set_stage "extract (existing project)"
"$REPO_ROOT/scripts/extract-template.sh" "$S3" >/dev/null 2>&1
assert_file_exists "$S3/.github/prompts/rw-onboard-project.prompt.md" "rw-onboard-project.prompt.md extracted (scenario3)"

# --- Step 12: Seed existing codebase signals ---
set_stage "seed existing codebase (sim)"
cat > "$S3/README.md" <<'EOF'
# 기존 서비스 코드베이스

이 저장소는 이미 구현이 진행된 서비스이며, 워크플로우 온보딩 대상입니다.
기능 개발은 기존 구조를 유지하면서 확장되어야 하며, 변경 전후 검증 경로가 명확해야 합니다.
문서 언어와 관계없이 파일 구조, 실행 경로, 검증 명령을 기준으로 작업 흐름을 결정합니다.
EOF

cat > "$S3/package.json" <<'EOF'
{
  "name": "existing-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "build": "tsc -p tsconfig.json"
  }
}
EOF

cat > "$S3/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "strict": true,
    "outDir": "dist"
  },
  "include": [
    "src/**/*"
  ]
}
EOF

mkdir -p "$S3/src"
cat > "$S3/src/index.ts" <<'EOF'
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
EOF

assert_file_exists "$S3/README.md" "scenario3 README exists"
assert_file_exists "$S3/package.json" "scenario3 package.json exists"
assert_file_exists "$S3/src/index.ts" "scenario3 source file exists"

# --- Step 13: rw-onboard-project (simulated) ---
set_stage "rw-onboard-project (sim)"
"$S3/scripts/rw-bootstrap-scaffold.sh" "$S3" >/dev/null 2>&1
assert_file_exists "$S3/.ai/tasks/TASK-01-bootstrap-workspace.md" "scenario3 TASK-01 initially scaffolded"

cat > "$S3/.ai/PLAN.md" <<EOF
# existing-app

## Overview
- Existing TypeScript repository with source files under src/.
- Manifest and build configuration are already present.
- Next step: define first feature via rw-feature.

## Current Codebase Snapshot
- Captured At: $TODAY
- Codebase Signals: MANIFEST_SIGNAL,SOURCE_SIGNAL,README_SIGNAL
- Core Stack: TypeScript, Node.js
- Key Paths: package.json, tsconfig.json, src/index.ts
- Verification Baseline: npm run build

## Feature Notes (append-only)
EOF

rm -f "$S3/.ai/tasks/TASK-01-bootstrap-workspace.md"

cat > "$S3/.ai/PROGRESS.md" <<EOF
# Progress

## Task Status
| Task | Title | Status | Commit |
|------|-------|--------|--------|

## Log
- **$TODAY** — Initial workspace scaffolded by rw-bootstrap-scaffold.
- **$TODAY** — Existing-project onboarding removed bootstrap TASK-01.
EOF

cat > "$S3/.ai/runtime/rw-onboard-sim-result.env" <<EOF
ONBOARD_RESULT=updated
CONTEXT_MODE=EXISTING_READY
CODEBASE_SIGNAL_COUNT=3
SNAPSHOT_RESULT=appended
TASK01_RESULT=removed
VERIFICATION_BASELINE=npm run build
NEXT_COMMAND=rw-feature
EOF

assert_file_not_exists "$S3/.ai/tasks/TASK-01-bootstrap-workspace.md" "scenario3 bootstrap TASK-01 removed"
assert_file_contains "$S3/.ai/PLAN.md" "## Current Codebase Snapshot" "scenario3 PLAN has snapshot section"
assert_file_contains "$S3/.ai/PLAN.md" "Verification Baseline: npm run build" "scenario3 PLAN has verification baseline"
assert_file_contains "$S3/.ai/PLAN.md" "## Feature Notes (append-only)" "scenario3 PLAN keeps Feature Notes section"
assert_file_not_contains "$S3/.ai/PROGRESS.md" "| TASK-01 |" "scenario3 PROGRESS has no TASK-01 row"
assert_progress_log_contains "$S3/.ai/PROGRESS.md" "Existing-project onboarding removed bootstrap TASK-01."
assert_file_contains "$S3/.ai/runtime/rw-onboard-sim-result.env" "CONTEXT_MODE=EXISTING_READY" "scenario3 context mode is EXISTING_READY"
assert_file_contains "$S3/.ai/runtime/rw-onboard-sim-result.env" "NEXT_COMMAND=rw-feature" "scenario3 next command is rw-feature"

# --- Step 14: Final result artifacts ---
set_stage "final-report artifacts"
mkdir -p "$RESULT_DIR"

if (cd "$S1" && npm run build --silent >/dev/null 2>&1); then
  CHECK_BUILD_STATUS="PASS"
  CHECK_BUILD_DETAIL="npm run build succeeded"
else
  CHECK_BUILD_STATUS="FAIL"
  CHECK_BUILD_DETAIL="npm run build failed"
fi

FINAL_GREET_OUTPUT="$(cd "$S1" && node dist/index.js greet World 2>&1 || true)"
if [ "$FINAL_GREET_OUTPUT" = "Hello, World!" ]; then
  CHECK_GREET_STATUS="PASS"
  CHECK_GREET_DETAIL='node dist/index.js greet World => "Hello, World!"'
else
  CHECK_GREET_STATUS="FAIL"
  CHECK_GREET_DETAIL="unexpected output: $FINAL_GREET_OUTPUT"
fi

FINAL_GOODBYE_OUTPUT="$(cd "$S1" && node dist/index.js goodbye World 2>&1 || true)"
if [ "$FINAL_GOODBYE_OUTPUT" = "Goodbye, World!" ]; then
  CHECK_GOODBYE_STATUS="PASS"
  CHECK_GOODBYE_DETAIL='node dist/index.js goodbye World => "Goodbye, World!"'
else
  CHECK_GOODBYE_STATUS="FAIL"
  CHECK_GOODBYE_DETAIL="unexpected output: $FINAL_GOODBYE_OUTPUT"
fi

if has_npm_test_script "$S1/package.json"; then
  if (cd "$S1" && npm test --silent >/dev/null 2>&1); then
    CHECK_TEST_STATUS="PASS"
    CHECK_TEST_DETAIL="npm test succeeded"
  else
    CHECK_TEST_STATUS="FAIL"
    CHECK_TEST_DETAIL="npm test failed"
  fi
else
  CHECK_TEST_STATUS="SKIPPED"
  CHECK_TEST_DETAIL="no npm test script"
fi

OVERALL_STATUS="PASS"
FAIL_REASON="null"
FAIL_PHASE="null"
if [ "$CHECK_BUILD_STATUS" = "FAIL" ] || [ "$CHECK_GREET_STATUS" = "FAIL" ] || [ "$CHECK_GOODBYE_STATUS" = "FAIL" ] || [ "$CHECK_TEST_STATUS" = "FAIL" ]; then
  OVERALL_STATUS="FAIL"
  FAIL_PHASE="final-report"
  FAIL_REASON="one or more final checks failed"
fi
if [ "${_FAIL:-0}" -gt 0 ]; then
  OVERALL_STATUS="FAIL"
  FAIL_PHASE="${FAIL_PHASE:-final-report}"
  FAIL_REASON="assertion failures=${_FAIL}"
fi

write_smoke_result_artifacts "$OVERALL_STATUS" "$FAIL_PHASE" "$FAIL_REASON"

assert_file_exists "$RESULT_JSON" "smoke result json created"
assert_file_exists "$RESULT_MD" "smoke result markdown created"
assert_command_succeeds "smoke result json schema-valid" "$S1/scripts/validate-smoke-result.sh" "$RESULT_JSON" "$S1/.ai/templates/SMOKE-RESULT-SCHEMA.json"
assert_file_contains "$RESULT_MD" "Status: $OVERALL_STATUS" "smoke result markdown has status"
assert_json_field_equals "$RESULT_JSON" "status" "$OVERALL_STATUS" "result status matches expected"
assert_json_field_equals "$RESULT_JSON" "total_phases" "$SMOKE_TOTAL_PHASES" "result total_phases is 8"
assert_json_field_equals "$RESULT_JSON" "dispatches" "$SMOKE_EXPECTED_DISPATCHES" "result dispatches is 10"

# ============================================================
# Final summary
# ============================================================
echo ""
if ! print_summary; then
  exit 1
fi
