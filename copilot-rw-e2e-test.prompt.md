# GitHub Copilot E2E Test Prompt (RW Workflow, no subagent)

아래 지시를 그대로 수행해줘. 목적은 `rw-new-project -> rw-feature -> rw-plan-lite -> rw-init` 워크플로우를 신규 프로젝트에서 회귀 테스트하는 것이다.

중요 제약:
- `rw-run-*`/subagent 관련 검증은 이번 테스트에서 제외한다.
- 실패를 숨기지 말고 즉시 `FAIL`로 기록한다.
- 각 단계 후 파일 검증을 반드시 수행한다.
- 사용자 문서 언어 기본값은 한국어로 간주한다(`.ai/CONTEXT.md` 기준).

## 0) 테스트 환경 준비

1. 아래 셸 명령으로 테스트 워크스페이스를 생성해라.

```bash
set -euo pipefail

SRC_REPO="$(pwd)"
TEST_ROOT="$(mktemp -d /tmp/rw-copilot-e2e-XXXXXX)"
CASE_EMPTY="$TEST_ROOT/case-empty"
CASE_READY="$TEST_ROOT/case-context-ready"

mkdir -p "$CASE_EMPTY" "$CASE_READY"
"$SRC_REPO/scripts/extract-template.sh" "$CASE_EMPTY"
"$SRC_REPO/scripts/extract-template.sh" "$CASE_READY"

echo "SRC_REPO=$SRC_REPO"
echo "TEST_ROOT=$TEST_ROOT"
```

2. `CASE_READY`에는 컨텍스트 신호를 추가해라.

```bash
cat > "$CASE_READY/README.md" <<'EOF'
# Billing CLI
작은 팀의 비용 정산을 자동화하는 CLI 도구.
EOF

cat > "$CASE_READY/package.json" <<'EOF'
{
  "name": "billing-cli",
  "version": "0.1.0",
  "description": "CLI for team billing automation",
  "scripts": {
    "build": "echo build",
    "test": "echo test"
  }
}
EOF
```

## 1) 공통 검증 함수 등록

아래 함수를 셸에서 실행해라.

```bash
set -euo pipefail

fail() { echo "FAIL: $1"; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_dir() { [ -d "$1" ] || fail "missing dir: $1"; }
assert_contains() { rg -q "$2" "$1" || fail "pattern not found ($2) in $1"; }
assert_not_contains() { rg -q "$2" "$1" && fail "unexpected pattern ($2) in $1" || true; }

assert_task_count_range() {
  local dir="$1"
  local min="$2"
  local max="$3"
  local c
  c=$(find "$dir/.ai/tasks" -maxdepth 1 -name 'TASK-*.md' | wc -l | tr -d ' ')
  [ "$c" -ge "$min" ] && [ "$c" -le "$max" ] || fail "task count out of range in $dir: $c (expected $min~$max)"
}

assert_no_task_02_plus_for_init_only() {
  local dir="$1"
  if find "$dir/.ai/tasks" -maxdepth 1 -name 'TASK-[0-9][0-9]-*.md' | rg -q 'TASK-0[2-9]|TASK-[1-9][0-9]'; then
    fail "TASK-02+ exists in init-only stage: $dir"
  fi
}

assert_korean_prose_in_tasks() {
  local dir="$1"
  local missing=0
  for f in "$dir"/.ai/tasks/TASK-*.md; do
    [ -f "$f" ] || continue
    if ! rg -q '[가-힣]' "$f"; then
      echo "NO_KOREAN_TEXT: $f"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || fail "some task files have no Korean prose"
}
```

## 2) CASE A: 완전 빈 프로젝트 경로 검증 (`rw-new-project -> rw-feature -> rw-plan-lite -> rw-init`)

작업 디렉터리를 `CASE_EMPTY`로 이동하고 아래 순서로 진행해라.

### A-1. `rw-new-project` 실행

- 입력 아이디어: `팀 회의 아젠다를 정리하고 공유하는 간단한 웹 앱`
- 질의응답이 나오면 아래 우선순위로 답변:
  - 대상 사용자: `3~10인 스타트업 팀 리더/PM`
  - 핵심 가치: `회의 준비 시간을 줄이고, 실행 항목 누락을 방지`
  - MVP 범위: `회의 생성/아젠다 작성/회의록 저장/액션아이템 체크`
  - 제외 범위: `외부 캘린더 연동, 알림, 권한 시스템`
  - 제약: `2주 내 MVP, 기술스택은 TypeScript 우선`
  - 검증 명령: `npm test` (없으면 `AI_DECIDE` 허용)

실행 후 검증:

```bash
cd "$CASE_EMPTY"
assert_dir ".ai"
assert_file ".ai/CONTEXT.md"
assert_file ".ai/PLAN.md"
assert_file ".ai/PROGRESS.md"
assert_file ".ai/tasks/TASK-01-bootstrap-workspace.md"
assert_no_task_02_plus_for_init_only "$CASE_EMPTY"
assert_contains ".ai/CONTEXT.md" "User document language \\(`.ai/\\*` docs\\): Korean by default"
assert_contains ".ai/PROGRESS.md" "^## Task Status"
assert_contains ".ai/PROGRESS.md" "^## Log"
assert_contains ".ai/PROGRESS.md" "^\\| Task \\| Title \\| Status \\| Commit \\|"
assert_contains ".ai/PROGRESS.md" "^\\| TASK-01 \\|"
assert_korean_prose_in_tasks "$CASE_EMPTY"
```

### A-2. `rw-feature` 실행

- 기능 한 줄 요약 입력: `월간 회의 요약 리포트를 생성하고 markdown으로 내보내기`
- 모호성 질문에는 가능한 한 구체적으로 답변하고, 최소 2라운드 이상 진행.

실행 전후 무결성 검증:

```bash
cd "$CASE_EMPTY"
cp .ai/PLAN.md /tmp/plan.before.md
cp .ai/PROGRESS.md /tmp/progress.before.md
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > /tmp/tasks.before.txt
```

`rw-feature` 실행 후:

```bash
cd "$CASE_EMPTY"
FEATURE_FILE_COUNT=$(find .ai/features -maxdepth 1 -name '*.md' ! -name 'FEATURE-TEMPLATE.md' ! -name 'README.md' | wc -l | tr -d ' ')
[ "$FEATURE_FILE_COUNT" -ge 1 ] || fail "feature file not created"

FEATURE_FILE=$(find .ai/features -maxdepth 1 -name '*.md' ! -name 'FEATURE-TEMPLATE.md' ! -name 'README.md' | sort | tail -n 1)
assert_contains "$FEATURE_FILE" "^Status: READY_FOR_PLAN$"
cmp -s .ai/PLAN.md /tmp/plan.before.md || fail "PLAN changed by rw-feature"
cmp -s .ai/PROGRESS.md /tmp/progress.before.md || fail "PROGRESS changed by rw-feature"
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > /tmp/tasks.after.feature.txt
cmp -s /tmp/tasks.before.txt /tmp/tasks.after.feature.txt || fail "tasks changed by rw-feature"
```

### A-3. `rw-plan-lite` 실행

- READY_FOR_PLAN 파일이 여러 개면 가장 최신 파일 하나를 선택.
- 질문이 나오면 경계/검증/의존성 관련 항목을 반드시 확정.

실행 후 검증:

```bash
cd "$CASE_EMPTY"
assert_task_count_range "$CASE_EMPTY" 4 7
assert_contains ".ai/PLAN.md" "^## Feature Notes \\(append-only\\)"
assert_contains ".ai/PROGRESS.md" "^\\| TASK-0[2-9] \\|"
assert_contains ".ai/PROGRESS.md" "pending"
assert_korean_prose_in_tasks "$CASE_EMPTY"

PLANNED_COUNT=$(rg -n "^Status: PLANNED$" .ai/features/*.md | wc -l | tr -d ' ')
[ "$PLANNED_COUNT" -ge 1 ] || fail "feature status was not updated to PLANNED"
```

### A-4. `rw-init` 재실행 (idempotency)

실행 전 스냅샷:

```bash
cd "$CASE_EMPTY"
cp .ai/PLAN.md /tmp/plan.before.reinit.md
cp .ai/PROGRESS.md /tmp/progress.before.reinit.md
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > /tmp/tasks.before.reinit.txt
```

`rw-init` 실행 후 검증:

```bash
cd "$CASE_EMPTY"
assert_contains ".ai/PLAN.md" "^## Feature Notes \\(append-only\\)"
assert_contains ".ai/PROGRESS.md" "^## Task Status"
assert_contains ".ai/PROGRESS.md" "^## Log"
find .ai/tasks -maxdepth 1 -name 'TASK-*.md' | sort > /tmp/tasks.after.reinit.txt
cmp -s /tmp/tasks.before.reinit.txt /tmp/tasks.after.reinit.txt || fail "task files changed unexpectedly by rw-init rerun"

# 완전 동일 파일까지 강제하지는 않음(보정 업데이트 허용), 대신 핵심 정보 보존 확인
assert_contains "/tmp/plan.before.reinit.md" "^## Feature Notes \\(append-only\\)"
assert_contains ".ai/PLAN.md" "^## Feature Notes \\(append-only\\)"
```

## 3) CASE B: 컨텍스트 신호가 있는 프로젝트에서 `rw-init` 검증

`CASE_READY`에서 `rw-init`만 실행한 뒤 검증해라.

```bash
cd "$CASE_READY"
assert_file "README.md"
assert_file "package.json"
```

`rw-init` 실행 후:

```bash
cd "$CASE_READY"
assert_file ".ai/PLAN.md"
assert_file ".ai/PROGRESS.md"
assert_file ".ai/tasks/TASK-01-bootstrap-workspace.md"
assert_no_task_02_plus_for_init_only "$CASE_READY"
assert_not_contains ".ai/PLAN.md" "프로젝트 목적 미정 \\(사용자 입력 필요\\)"
assert_not_contains ".ai/PLAN.md" "기술 스택 미정"
assert_contains ".ai/PROGRESS.md" "^\\| TASK-01 \\|"
assert_korean_prose_in_tasks "$CASE_READY"
```

## 4) 결과 리포트 출력

아래 형식으로 최종 결과를 출력해라.

```md
# RW Workflow E2E Report

## Environment
- SRC_REPO:
- TEST_ROOT:
- Timestamp:

## Case A (empty project)
- A-1 rw-new-project: PASS/FAIL
- A-2 rw-feature: PASS/FAIL
- A-3 rw-plan-lite: PASS/FAIL
- A-4 rw-init rerun: PASS/FAIL

## Case B (context-ready init)
- B-1 rw-init: PASS/FAIL

## Key Findings
- 언어 정책 반영 여부 (TASK 제목/본문 한국어)
- TASK-01 제한 준수 여부
- rw-feature의 비침범성(PLAN/PROGRESS/tasks 미변경) 여부
- rw-init 재실행 idempotency 여부

## Failed Checks (if any)
- [체크명] 원인 / 관련 파일 / 재현 명령

## Verdict
- OVERALL: PASS/FAIL
```

실패가 한 개라도 있으면 `OVERALL: FAIL`로 끝내라.
