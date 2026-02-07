# Ralph Wiggum Lite 가이드

`runSubagent` 기반으로 **기능 계획 → 태스크 구현**만 간결하게 돌리는 운영 가이드입니다.

## 최소 구조

```text
.ai/
├── PLAN.md
├── PROGRESS.md
└── tasks/

.github/prompts/
├── rw-init.prompt.md
├── rw-archive.prompt.md
├── rw-plan-lite.prompt.md
├── rw-run-lite.prompt.md
├── rw-plan-strict.prompt.md
└── rw-run-strict.prompt.md
```

## 언어 정책

- 기준 파일: `.ai/CONTEXT.md`
- `.github/prompts/*.prompt.md`는 영어 본문으로 유지한다.
- 각 프롬프트는 `Step 0 (Mandatory)`에서 `.ai/CONTEXT.md`를 먼저 읽고, 실패 시 `LANG_POLICY_MISSING`으로 중지한다.
- `.ai/*` 운영 문서는 기본 한국어로 유지한다.
- 기존(legacy) 영어 문서는 즉시 전면 번역을 강제하지 않으며, 신규 작성/수정 시 한국어를 우선한다.
- 언어가 섞여 충돌할 경우 `.ai/CONTEXT.md` 규칙을 우선 적용한다.
- 단, parser-safe 토큰(`Task Status`, `Log`, `pending/in-progress/completed`)은 문서 언어와 무관하게 반드시 영어로 유지한다.

## 모드 선택

- `Lite`:
  - 계획: `.github/prompts/rw-plan-lite.prompt.md`
  - 실행: `.github/prompts/rw-run-lite.prompt.md`
  - 특징: 빠르고 단순함, 단일 세션 가정, archive 임계치 도달 시 경고만 출력(실행 지속)
- `Strict`:
  - 계획: `.github/prompts/rw-plan-strict.prompt.md`
  - 실행: `.github/prompts/rw-run-strict.prompt.md`
  - 특징: reviewer 루프 + archive는 `rw-archive` 수동 실행

## 사용 방법

1. VS Code Copilot Chat에서 새 대화를 연다.
2. `.ai/` 구조가 없으면 `rw-init.prompt.md`를 먼저 실행해 초기화한다(초기 1회).
3. 선택한 모드의 `rw-plan-*.prompt.md` 내용을 붙여넣고 실행해 태스크를 만든다.
4. 같은 모드의 `rw-run-*.prompt.md` 내용을 붙여넣고 실행해 오케스트레이션 루프를 돌린다.
5. 진행 상태는 `.ai/PROGRESS.md`에서 확인한다.
6. 중단하려면 `.ai/PAUSE.md`를 생성하고, 재개하려면 삭제한다.

## 실행 순서

1. 초기화(필요 시): `rw-init.prompt.md`
2. 기능 추가 계획: 선택한 모드의 `rw-plan-*.prompt.md`
3. 태스크 구현 루프: 선택한 모드의 `rw-run-*.prompt.md`
4. 상태 확인: `.ai/PROGRESS.md`

## 보조 프롬프트 사용 시점

- `rw-init.prompt.md`:
  - 새 프로젝트이거나 `.ai/` 폴더가 없을 때만 실행한다.
  - 이미 운영 중인 프로젝트에서는 재초기화 대신 `rw-plan-*`으로 기능을 추가한다.
- `rw-archive.prompt.md`:
  - `Lite`/`Strict` 모두에서 `PROGRESS.md`가 커졌을 때 수동 실행한다.
  - 기준: `PROGRESS.md > 8000 chars` 또는 `completed > 20` 또는 `log > 40`.
  - 반드시 run 루프가 멈춘 상태(`.ai/PAUSE.md` 존재)에서 실행한다.
  - archive 중에는 `.ai/ARCHIVE_LOCK`이 생성되며, lock이 있으면 다른 archive 실행을 중단한다.

## Lite 운영 규칙

- `runSubagent`가 없으면 자동 루프를 중단하고 수동 fallback 절차를 출력한다.
- 오케스트레이터는 `src/` 코드를 직접 수정하지 않는다.
- `PLAN.md`는 `Feature Notes`만 append 한다.
- 태스크는 `TASK-XX` 번호를 유지한다.
- **동시에 여러 오케스트레이터를 실행하지 않는다**(충돌 방지).
- archive 임계치(`completed > 20` 또는 `PROGRESS > 8000 chars`)를 넘기면 경고를 출력하지만 실행은 계속된다.
- 경고가 나오면 `.ai/PAUSE.md`를 만든 뒤 `rw-archive.prompt.md`를 수동 실행하고 재개하는 것을 권장한다.
- 중단이 필요하면 `.ai/PAUSE.md`를 만든다.

## runSubagent fallback

- 트리거: `runSubagent unavailable` 감지 시
- 공통 동작:
  - 자동 오케스트레이션 루프를 즉시 중지한다.
  - `MANUAL_FALLBACK_REQUIRED` 안내와 함께 수동 체크리스트를 출력한다.
  - 사용자는 단일 태스크를 수동 구현/검증/커밋하고 `PROGRESS`를 갱신한 뒤 프롬프트를 재실행한다.
- Strict 추가 규칙:
  - 수동 리뷰 실패 시 `REVIEW_FAIL TASK-XX (n/3)`를 기록하고 상태를 `pending`으로 되돌린다.
  - 3회 실패 시 `REVIEW-ESCALATE TASK-XX (3/3)`를 기록하고 중단한다.

## 태스크 템플릿 (요약)

```markdown
# TASK-XX: 제목

## Dependencies
## Description
## Acceptance Criteria
## Files to Create/Modify
## Verification
```

## PROGRESS 템플릿 (요약)

```markdown
# 진행 현황

## Task Status
| Task | Title | Status | Commit |

## Log
- **YYYY-MM-DD** — TASK-XX completed: ...
```

## 자주 있는 실패

- `runSubagent unavailable`: 실행 환경/모델에서 도구 지원 여부 확인
- TASK 번호 충돌: 최신 브랜치로 업데이트 후 선택 모드의 `rw-plan-*` 재실행
- PROGRESS 누락: Task Status 행과 Log를 수동 보정 후 선택 모드의 `rw-run-*` 재개
- `REVIEW-ESCALATE` 발생(Strict): 동일 TASK 리뷰 3회 실패 상태이므로 태스크/요구사항을 수동 수정한 뒤 재실행
