# GitHub Copilot Smoke Test Prompt (RW Lite 핵심 경로)

아래 지시를 그대로 수행해줘. 목적은 RW 워크플로우가 현재 Copilot 환경에서 **빠르게 실행 가능한지** 확인하는 것이다.

검증 경로(축약):
- `rw-new-project -> rw-feature -> rw-plan-lite -> rw-run-lite`

중요 제약:
- `rw-run-lite`는 반드시 Copilot Chat **최상위(Top-level) 턴**에서 실행한다.
- 실행 중 `runSubagent unavailable` 또는 `MANUAL_FALLBACK_REQUIRED` 또는 `TOP_LEVEL_REQUIRED`가 나오면 즉시 `FAIL`.
- 실패를 숨기지 말고 즉시 `FAIL`로 기록한다.

## 0) 테스트 환경 준비

```bash
set -euo pipefail

SRC_REPO="$(pwd)"
TEST_BASE="$SRC_REPO/.tmp/rw-copilot-smoke"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
TEST_ROOT="$TEST_BASE/$RUN_ID"
CASE_LITE="$TEST_ROOT/case-lite"
SNAPSHOT_DIR="$TEST_ROOT/_snapshots"

mkdir -p "$CASE_LITE" "$SNAPSHOT_DIR"
"$SRC_REPO/scripts/extract-template.sh" "$CASE_LITE"

cd "$CASE_LITE"
git init -q
git config user.name "rw-smoke"
git config user.email "rw-smoke@example.com"
git add -A
git commit -qm "chore: bootstrap rw template"

echo "SRC_REPO=$SRC_REPO"
echo "TEST_ROOT=$TEST_ROOT"
echo "CASE_LITE=$CASE_LITE"
```

## 1) 공통 검증 함수

```bash
set -euo pipefail

fail() { echo "FAIL: $1"; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_contains() { rg -q "$2" "$1" || fail "pattern not found ($2) in $1"; }

assert_rw_run_completed() {
  local dir="$1"
  local progress="$dir/.ai/PROGRESS.md"
  assert_file "$progress"
  rg -n '^\| TASK-[0-9][0-9] \| .* \| pending \|' "$progress" >/dev/null && fail "pending task remains"
  rg -n '^\| TASK-[0-9][0-9] \| .* \| in-progress \|' "$progress" >/dev/null && fail "in-progress task remains"
  rg -n '^\| TASK-[0-9][0-9] \| .* \| completed \|' "$progress" >/dev/null || fail "no completed tasks"
}
```

## 2) `rw-new-project`

- 입력 아이디어: `팀 회의 액션아이템을 기록하고 요약하는 최소 CLI`
- 질의응답이 나오면 아래로 답변:
  - 대상 사용자: `소규모 팀 리더/PM`
  - 핵심 가치: `회의 후 액션 누락 방지`
  - MVP 범위: `액션아이템 추가/목록/완료 처리`
  - 제외 범위: `외부 연동, 인증, 권한`
  - 제약: `Node.js + TypeScript, 작은 범위`
  - 검증 명령: `npm test` (없으면 `AI_DECIDE`)

실행 후 검증:

```bash
cd "$CASE_LITE"
assert_file ".ai/CONTEXT.md"
assert_file ".ai/PLAN.md"
assert_file ".ai/PROGRESS.md"
assert_file ".ai/tasks/TASK-01-bootstrap-workspace.md"
assert_contains ".ai/PROGRESS.md" "^## Task Status"
assert_contains ".ai/PROGRESS.md" "^## Log"
BOOTSTRAP_FEATURE=$(find .ai/features -maxdepth 1 -name '*bootstrap*foundation*.md' | head -n 1)
[ -n "$BOOTSTRAP_FEATURE" ] || fail "bootstrap feature not found"
assert_contains "$BOOTSTRAP_FEATURE" "^Status: PLANNED$"
```

## 3) `rw-feature`

- 기능 요약 입력: `액션아이템 목록을 markdown 리포트로 내보내는 명령 추가`

실행 전후 무결성 체크:

```bash
cd "$CASE_LITE"
cp .ai/PLAN.md "$SNAPSHOT_DIR/plan.before.md"
cp .ai/PROGRESS.md "$SNAPSHOT_DIR/progress.before.md"
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > "$SNAPSHOT_DIR/tasks.before.txt"
```

`rw-feature` 실행 후:

```bash
cd "$CASE_LITE"
FEATURE_FILE=$(find .ai/features -maxdepth 1 -name '*.md' ! -name 'FEATURE-TEMPLATE.md' ! -name 'README.md' | sort | tail -n 1)
[ -n "$FEATURE_FILE" ] || fail "feature file not created"
assert_contains "$FEATURE_FILE" "^Status: READY_FOR_PLAN$"
cmp -s .ai/PLAN.md "$SNAPSHOT_DIR/plan.before.md" || fail "PLAN changed by rw-feature"
cmp -s .ai/PROGRESS.md "$SNAPSHOT_DIR/progress.before.md" || fail "PROGRESS changed by rw-feature"
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > "$SNAPSHOT_DIR/tasks.after.feature.txt"
cmp -s "$SNAPSHOT_DIR/tasks.before.txt" "$SNAPSHOT_DIR/tasks.after.feature.txt" || fail "tasks changed by rw-feature"
```

## 4) `rw-plan-lite`

- READY 후보가 여러 개면 Copilot 단일 선택 질문에서 방금 만든 파일을 선택한다(`CANCEL` 금지).

실행 전 스냅샷:

```bash
cd "$CASE_LITE"
TASK_COUNT_BEFORE_PLAN=$(find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | wc -l | tr -d ' ')
```

실행 후 검증:

```bash
cd "$CASE_LITE"
TASK_COUNT_AFTER_PLAN=$(find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | wc -l | tr -d ' ')
TASK_DELTA=$((TASK_COUNT_AFTER_PLAN - TASK_COUNT_BEFORE_PLAN))
[ "$TASK_DELTA" -ge 3 ] && [ "$TASK_DELTA" -le 6 ] || fail "rw-plan-lite task delta invalid: $TASK_DELTA"
PLANNED_COUNT=$(rg -n "^Status: PLANNED$" .ai/features/*.md | wc -l | tr -d ' ')
[ "$PLANNED_COUNT" -ge 2 ] || fail "expected at least two PLANNED features"
```

## 5) `rw-run-lite` (핵심)

- 반드시 Copilot Chat Top-level 턴에서 실행한다.

실행 전 스냅샷:

```bash
cd "$CASE_LITE"
COMMITS_BEFORE_RUN_LITE="$(git rev-list --count HEAD)"
echo "COMMITS_BEFORE_RUN_LITE=$COMMITS_BEFORE_RUN_LITE"
```

`rw-run-lite` 실행 후 검증:

```bash
cd "$CASE_LITE"
COMMITS_AFTER_RUN_LITE="$(git rev-list --count HEAD)"
[ "$COMMITS_AFTER_RUN_LITE" -gt "$COMMITS_BEFORE_RUN_LITE" ] || fail "git commit count did not increase"
assert_rw_run_completed "$CASE_LITE"
if rg -n '^\| TASK-[0-9][0-9] \| .* \| completed \| - \|' .ai/PROGRESS.md >/dev/null; then
  fail "completed tasks still have '-' commit in PROGRESS"
fi
```

## 6) 결과 리포트

아래 형식으로 최종 결과를 출력해라.

```md
# RW Smoke Test Report

## Environment
- SRC_REPO:
- TEST_ROOT:
- Timestamp:

## Checks
- rw-new-project: PASS/FAIL
- rw-feature: PASS/FAIL
- rw-plan-lite: PASS/FAIL
- rw-run-lite: PASS/FAIL

## Failed Checks (if any)
- [체크명] 원인 / 관련 파일 / 재현 명령

## Verdict
- OVERALL: PASS/FAIL
```

실패가 한 개라도 있으면 `OVERALL: FAIL`로 끝내라.
