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

## 모드 선택

- `Lite`:
  - 계획: `.github/prompts/rw-plan-lite.prompt.md`
  - 실행: `.github/prompts/rw-run-lite.prompt.md`
  - 특징: 빠르고 단순함, 단일 세션 가정
- `Strict`:
  - 계획: `.github/prompts/rw-plan-strict.prompt.md`
  - 실행: `.github/prompts/rw-run-strict.prompt.md`
  - 특징: reviewer 루프 + PROGRESS archive 규칙 포함

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
  - `Lite` 모드에서 `PROGRESS.md`가 커졌을 때 수동 실행한다.
  - 기준: `PROGRESS.md > 8000 chars` 또는 `completed > 20` 또는 `log > 40`.
  - 반드시 `rw-run-lite`가 멈춘 상태에서 실행한다.
  - `Strict` 모드에서는 `rw-run-strict` 내장 archive를 사용하므로 별도 `rw-archive`를 동시에 실행하지 않는다.

## Lite 운영 규칙

- `runSubagent`가 없으면 즉시 실패 처리한다.
- 오케스트레이터는 `src/` 코드를 직접 수정하지 않는다.
- `PLAN.md`는 `Feature Notes`만 append 한다.
- 태스크는 `TASK-XX` 번호를 유지한다.
- **동시에 여러 오케스트레이터를 실행하지 않는다**(충돌 방지).
- 중단이 필요하면 `.ai/PAUSE.md`를 만든다.

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
# Progress

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
