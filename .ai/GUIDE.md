# Ralph Wiggum 운영 가이드

`runSubagent` 기반으로 **기능 계획 → 태스크 구현 → 배치 리뷰**를 간결하게 돌리는 운영 가이드입니다.

## 최소 구조

```text
.ai/
├── PLAN.md
├── PROGRESS.md
├── features/
├── templates/
└── tasks/

.github/prompts/
├── rw-init.prompt.md
├── rw-new-project.prompt.md
├── rw-doctor.prompt.md
├── rw-feature.prompt.md
├── rw-plan.prompt.md
├── rw-run.prompt.md
├── rw-review.prompt.md
└── rw-archive.prompt.md

scripts/
├── rw-resolve-target-root.sh
└── rw-bootstrap-scaffold.sh
```

## 언어 정책

- 기준 파일: `.ai/CONTEXT.md`
- 운영 프롬프트(`.github/prompts/rw-*.prompt.md`)는 영어 본문으로 유지한다.
- 별도 `copilot-rw-*` 테스트 프롬프트는 이 브랜치에서 유지하지 않는다.
- 운영 프롬프트(`rw-*`)는 `Step 0 (Mandatory)`에서 `.ai/CONTEXT.md`를 먼저 읽고, 실패 시 `LANG_POLICY_MISSING`으로 중지한다.
- `.ai/*` 운영 문서는 기본 한국어로 유지한다.
- 기존(legacy) 영어 문서는 즉시 전면 번역을 강제하지 않으며, 신규 작성/수정 시 한국어를 우선한다.
- 언어가 섞여 충돌할 경우 `.ai/CONTEXT.md` 규칙을 우선 적용한다.
- 단, parser-safe 토큰(`Task Status`, `Log`, `pending/in-progress/completed`)은 문서 언어와 무관하게 반드시 영어로 유지한다.

## 실행 정책

- 실행 프롬프트는 단일 `rw-run.prompt.md`만 사용한다.
- 리뷰는 별도 수동 단계 `rw-review.prompt.md`로 수행한다.
- archive 임계치 도달 시 `rw-run`은 중단하고 `rw-archive`를 수동 실행한다.
- 대화형 입력 fallback은 `.github/prompts/RW-INTERACTIVE-POLICY.md` 단일 정책을 따른다.
- target root 해석은 `scripts/rw-resolve-target-root.sh`를 공통 기준으로 사용한다.
- 신규 스캐폴딩은 `scripts/rw-bootstrap-scaffold.sh`를 공통 기준으로 사용한다.

## 사용 방법

1. VS Code Copilot Chat에서 새 대화를 연다.
2. 신규/빈 저장소에서는 `rw-new-project.prompt.md`를 먼저 실행한다(초기 1회).
   - `rw-new-project`는 `rw-init + discovery + bootstrap feature/task 분해` 통합 프롬프트다.
   - 스캐폴딩은 우선 `scripts/rw-bootstrap-scaffold.sh`를 사용한다.
   - `.ai` 스캐폴딩, 프로젝트 방향 확정, bootstrap task 생성까지 한 번에 수행한다.
   - 실행 중 아래 타깃 포인터를 현재 워크스페이스 루트 기준으로 자동 갱신한다.
     - `workspace-root/.ai/runtime/rw-active-target-id.txt` -> `workspace-root`
     - `workspace-root/.ai/runtime/rw-targets/workspace-root.env` -> `TARGET_ROOT=<workspace-root>`
     - `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)
3. `rw-run.prompt.md` 실행 전 `rw-doctor.prompt.md`를 먼저 실행해 preflight를 확인한다.
   - VS Code 워크스페이스 루트와 실제 대상 프로젝트 루트가 다르면(테스트 하니스 경로 예: `.tmp/.../case-*`), active target id + registry를 먼저 갱신한다.
     - `workspace-root/.ai/runtime/rw-active-target-id.txt`
     - `workspace-root/.ai/runtime/rw-targets/<target-id>.env` (`TARGET_ROOT=<absolute-path>`)
   - legacy 호환을 위해 `workspace-root/.ai/runtime/rw-active-target-root.txt`도 같은 경로로 동기화한다.
   - 비대화형 실행에서도 같은 규칙으로 타깃 루트를 고정한다.
   - 수동 전환이 필요하면 워크스페이스 루트에서:
     - `./scripts/rw-target-registry.sh set-active "$(pwd)" <target-id> "<absolute-target-root>"`
     - `./scripts/rw-target-registry.sh resolve-active "$(pwd)"`
4. `rw-run.prompt.md` 내용을 붙여넣고 실행해 bootstrap 태스크를 먼저 구현한다.
   - `rw-run`도 동일한 타깃 포인터 세트(`active-target-id`, `rw-targets/*.env`, legacy root pointer)를 읽어 동작한다(인자 전달 불필요).
5. `rw-run` 완료 후 `rw-review.prompt.md`를 실행한다(배치 리뷰).
6. 이후 추가 기능은 `rw-feature.prompt.md` -> `rw-plan.prompt.md` -> `rw-doctor.prompt.md` -> `rw-run.prompt.md` 순서로 진행한다.
7. 진행 상태는 `.ai/PROGRESS.md`에서 확인한다.
8. 중단하려면 `.ai/PAUSE.md`를 생성하고, 재개하려면 삭제한다.
9. 스캐폴딩만 따로 필요하면 `rw-init.prompt.md`를 대안으로 사용한다.
   - `rw-init`도 동일한 타깃 포인터 3종(`active-target-id`, `rw-targets/*.env`, legacy root pointer)을 자동 갱신한다.

## 실행 순서

1. 신규 프로젝트 초기화+방향 확정+bootstrap 분해: `rw-new-project.prompt.md`
2. 실행 전 preflight: `rw-doctor.prompt.md`
3. bootstrap 태스크 구현 루프: `rw-run.prompt.md`
4. bootstrap 배치 리뷰: `rw-review.prompt.md`
5. 추가 기능 정의: `rw-feature.prompt.md`
6. 추가 기능 계획: `rw-plan.prompt.md`
7. 추가 기능 구현 전 preflight: `rw-doctor.prompt.md`
8. 추가 기능 구현 루프: `rw-run.prompt.md`
9. 추가 기능 배치 리뷰: `rw-review.prompt.md`
10. 상태 확인: `.ai/PROGRESS.md`
11. 스캐폴딩만 필요할 때(대안): `rw-init.prompt.md`

## Feature 파일 입력 규칙

- `rw-plan`은 **입력 인자 없이** `.ai/features/*.md`만 사용한다.
- 파일 선택 규칙:
  - 입력 후보는 `.ai/features/*.md` 중 `FEATURE-TEMPLATE.md`, `README.md`를 제외한 파일
  - `Status: READY_FOR_PLAN` 파일이 1개면 그 파일을 사용한다.
  - READY 후보가 2개 이상이면 최신 파일명(lexical sort 마지막)을 자동 선택한다.
  - 자동 선택 시 `FEATURE_MULTI_READY_AUTOSELECTED=<filename>`를 출력한다.
  - 권장 파일명: `YYYYMMDD-HHMM-<slug>.md`
- 에러 처리(정확한 토큰):
  - `.ai/features` 폴더가 없거나 읽기 불가: `FEATURES_DIR_MISSING`
  - `.ai/features`에 `.md` 파일이 없음: `FEATURE_FILE_MISSING`
  - `.md` 파일은 있으나 `Status: READY_FOR_PLAN` 후보 없음: `FEATURE_NOT_READY`
- 에러 발생 시 첫 줄은 에러 토큰을 출력하고, 다음 줄에 생성/수정 가이드를 출력한 뒤 즉시 중단한다.
- 에러 시 보완 질문은 하지 않는다.
- plan 완료 시 선택된 feature 파일 상태를 `PLANNED`로 갱신한다.
- 권장 상태값(단순화): `DRAFT` -> `READY_FOR_PLAN` -> `PLANNED`
- `rw-plan`은 결정형 모드로 동작하며 추가 질문을 하지 않는다.
- 보완이 부족해도 안전 기본값으로 계획을 진행한다:
  - Constraints: 기존 동작 비파괴, 범위 최소화, 프로젝트 표준 검증 명령 통과
  - Acceptance: 사용자 기능 동작, 오류 메시지 명확성, 최소 1개 이상의 표준 검증 명령 exit code 0

## 보조 프롬프트 사용 시점

- `rw-init.prompt.md`:
  - 스캐폴딩만 필요한 경우 사용하는 비대화형 대안 프롬프트다.
  - `CONTEXT`, PLAN/PROGRESS 뼈대, optional `TASK-01` 1개까지만 다룬다.
  - 신규 저장소에서는 기본적으로 `rw-new-project`를 우선 권장한다.
- `rw-new-project.prompt.md`:
  - `rw-init + discovery + bootstrap feature/task 분해` 통합 프롬프트다.
  - 빈/템플릿 저장소에서 `.ai` 스캐폴딩, 프로젝트 방향 확정, bootstrap task 생성을 한 번에 수행한다.
  - 기본값으로 bootstrap 산출물(`.ai/*`)을 1회 커밋한다 (`chore(rw): bootstrap workspace via rw-new-project`).
  - `projectIdea`에 `[NO_AUTO_COMMIT]`를 넣거나 `.ai/runtime/rw-no-autocommit.flag`가 있으면 auto-commit을 건너뛴다.
  - discovery는 질문형을 유지하되 고정 4개 항목(대상 사용자/핵심 가치/MVP 범위/제약+검증 기준)만 수집한다.
  - discovery 라운드는 최대 2회로 제한한다(1회 필수 + 1회 보완 선택).
  - `PLAN.md`의 `개요`를 구체화하고 `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md`를 생성한다.
  - bootstrap feature는 이 프롬프트에서 생성/소비할 수 있으며, 일반 기능 분해는 `rw-plan`의 책임이다.
- `rw-feature.prompt.md`:
  - `rw-plan` 실행 전에 feature 입력 파일을 만들 때 사용한다.
  - 한 줄 입력(`featureSummary`)을 받아 feature 파일을 상세 스펙 형태로 생성한다.
  - 선택형 질문은 필요한 경우(고영향 모호성 해소) 최소한으로만 사용한다.
  - 모호성이 남으면 2~5 라운드 보완 질문을 수행하고, 각 라운드에서 1~3개의 집중 질문을 한다.
  - 입력이 비어 있고 보완 질문 이후에도 요약이 없으면 `FEATURE_SUMMARY_MISSING`으로 중단한다.
  - 생성 파일은 `Status: READY_FOR_PLAN`으로 저장된다.
  - feature 파일 본문은 한국어로 작성하고, 기계 파싱 토큰(`Status`, `READY_FOR_PLAN`, `PLANNED`)만 영어를 유지한다.
- `rw-doctor.prompt.md`:
  - `rw-run` 실행 전 preflight 검사 프롬프트다.
  - 검사 항목: top-level 실행 여부, `runSubagent` 가용성, git 저장소 상태, `.ai` 필수 경로/파일 접근성.
  - 기본 타깃 루트는 아래 순서로 읽는다.
    1) `workspace-root/.ai/runtime/rw-active-target-id.txt`
    2) `workspace-root/.ai/runtime/rw-targets/<target-id>.env` (`TARGET_ROOT=...`)
    3) `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)
  - 포인터가 비어 있거나 유효하지 않은 경로를 가리키면 `RW_TARGET_ROOT_INVALID`로 즉시 중단한다.
  - 통과 시 `RW_DOCTOR_PASS`, 실패 시 `RW_DOCTOR_BLOCKED`를 출력한다.
- `rw-review.prompt.md`:
  - 수동 리뷰 전용 프롬프트다(top-level 실행).
  - active `Task Status`의 completed 태스크를 배치로 검증한다.
  - 태스크별 reviewer subagent를 디스패치한다.
  - 병렬은 결정형 정책으로만 허용한다:
    - 모든 후보 task 파일에 `Review Parallel: SAFE`가 있을 때만 병렬
    - 병렬 batch size는 고정 2
    - 그 외에는 순차 실행
  - 리뷰 결과를 집계한 뒤 `REVIEW_OK`/`REVIEW_FAIL`/`REVIEW-ESCALATE`를 `PROGRESS`에 반영한다.
- `rw-archive.prompt.md`:
  - `PROGRESS.md`가 커졌을 때 수동 실행한다.
  - 기준: `PROGRESS.md > 8000 chars` 또는 `completed > 20` 또는 `log > 40`.
  - 반드시 run 루프가 멈춘 상태(`.ai/PAUSE.md` 존재)에서 실행한다.
  - archive 중에는 `.ai/ARCHIVE_LOCK`이 생성되며, lock이 있으면 다른 archive 실행을 중단한다.

## Next-step output contract

- 운영 프롬프트(`rw-*`) 종료 시, 다음 액션은 `NEXT_COMMAND=<...>` 한 줄로 안내한다.
- 단, Step 0 이전의 즉시 중단 경로는 예외일 수 있다.
- 사용자는 자유 텍스트 설명보다 `NEXT_COMMAND`를 우선 기준으로 다음 프롬프트를 실행한다.
- 기본 기대값:
  - `rw-init` -> `NEXT_COMMAND=rw-new-project` 또는 `rw-feature`
  - `rw-new-project` -> `NEXT_COMMAND=rw-run` 또는 `rw-feature`
  - `rw-feature` -> `NEXT_COMMAND=rw-plan`
  - `rw-plan` -> `NEXT_COMMAND=rw-run`
  - `rw-doctor` -> `NEXT_COMMAND=rw-run` (PASS), `NEXT_COMMAND=rw-doctor` (BLOCKED 후 재검증)
  - `rw-run` -> `NEXT_COMMAND=rw-review` / `rw-archive` / `rw-doctor` / `rw-run`
  - `rw-review` -> `NEXT_COMMAND=rw-archive` / `rw-run` / `rw-doctor`
  - `rw-archive` -> `NEXT_COMMAND=rw-run`

## rw-run 운영 규칙

- `runSubagent`가 없으면 `RW_ENV_UNSUPPORTED`를 출력하고 자동 루프를 즉시 중단한다.
- `rw-run` 실행 전 `rw-doctor`를 먼저 실행해 환경을 확인한다.
- `rw-doctor`와 `rw-run`은 동일한 타깃 포인터 세트(`.ai/runtime/rw-active-target-id.txt`, `.ai/runtime/rw-targets/*.env`, legacy `.ai/runtime/rw-active-target-root.txt`)를 사용해야 한다(루트 불일치 방지).
- 오케스트레이터는 제품 코드를 직접 수정하지 않는다.
- 제품 코드 경로는 저장소 구조(웹/앱/게임/유니티 등)에 따라 다르므로 `src/` 고정 가정을 두지 않는다.
- `PLAN.md`는 `Feature Notes`만 append 한다.
- 태스크는 `TASK-XX` 번호를 유지한다.
- 오케스트레이터는 루프마다 정확히 1개 태스크를 `LOCKED_TASK_ID`로 잠그고 subagent에 전달한다.
- 한 번의 dispatch에서 새로 `completed`로 바뀌는 태스크는 정확히 1개여야 하며, 반드시 `LOCKED_TASK_ID`와 같아야 한다.
- **동시에 여러 오케스트레이터를 실행하지 않는다**(충돌 방지).
- archive 임계치(`completed > 20` 또는 `PROGRESS > 8000 chars` 또는 `log > 40`)를 넘기면 즉시 중단한다.
- 중단 시 `.ai/PAUSE.md`를 유지한 상태로 `rw-archive.prompt.md`를 수동 실행한 후 `rw-run`을 재개한다.
- 중단이 필요하면 `.ai/PAUSE.md`를 만든다.

## runSubagent fallback

- 트리거: `runSubagent unavailable` 감지 시
- 공통 동작:
  - 자동 오케스트레이션 루프를 즉시 중지한다.
  - `RW_ENV_UNSUPPORTED`를 출력하고 즉시 종료한다.
  - `rw-doctor`를 다시 실행해 환경을 점검하고, `runSubagent` 지원 환경에서 `rw-run`을 재실행한다.

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

## 검증 호출 정리 (사용자 관점)

- 이 브랜치에서는 복잡한 `copilot-rw-*` 테스트 프롬프트를 사용하지 않는다.
- 운영 검증은 코어 루프를 직접 실행한다:
  1. `rw-new-project`
  2. `rw-doctor`
  3. `rw-run`
  4. `rw-review` (batch review after run)
  5. `rw-feature`
  6. `rw-plan`
  7. `rw-doctor`
  8. `rw-run`
  9. `rw-review`

규칙:
- 한 턴에서 프롬프트는 하나만 실행한다.
- 실패 시 토큰 1개만 기준으로 원인을 수정하고 재실행한다.

## 자주 있는 실패

- `runSubagent unavailable`: 실행 환경/모델에서 도구 지원 여부 확인
- `RW_TARGET_ROOT_INVALID`: `.ai/runtime/rw-active-target-id.txt` + `.ai/runtime/rw-targets/<target-id>.env` 또는 legacy `.ai/runtime/rw-active-target-root.txt`를 절대 경로로 복구 후 재실행
- TASK 번호 충돌: 최신 브랜치로 업데이트 후 `rw-plan` 재실행
- PROGRESS 누락: Task Status 행과 Log를 수동 보정 후 `rw-run` 재개
- `REVIEW-ESCALATE` 발생: 태스크/요구사항을 수동 수정 후 `REVIEW-ESCALATE-RESOLVED TASK-XX: <해결 요약>`를 `PROGRESS` Log에 append하고 `rw-run`을 재실행
