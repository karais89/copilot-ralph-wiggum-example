# Plan: rw-init 역할 경계 재정의 및 프롬프트 수정

## TL;DR

**문제**: `rw-init`가 프롬프트의 "exactly 1 bootstrap task" 제한을 무시하고, 상세 PRD 작성 + Task 10개 일괄 생성을 수행함. 이는 `rw-feature` → `rw-plan`의 역할을 침범하는 것이며, 새 프로젝트에서 init이 "초기화"가 아닌 "전체 설계"를 해버리는 결과를 낳음.

**원인**: [rw-init.prompt.md](.github/prompts/rw-init.prompt.md)의 Step 1이 "Project goal, Scope boundaries, Constraints"를 추론하라고 지시하고, Step 3이 "concise PRD"를 작성하라고 함 → AI가 이를 상세 제품 요구사항 작성으로 해석. "exactly 1 bootstrap task" 제약은 텍스트 중간에 묻혀 AI가 무시.

**해결**: `rw-init`의 책임을 **인프라 스캐폴딩**으로 명확히 제한하고, 프롬프트 전반에 걸쳐 역할 경계를 강화.

---

## Steps

**1. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — Step 1 축소**
- 현재 Step 1의 "Infer: Project goal / Scope boundaries / Constraints"를 제거
- 대신 추론 범위를 **프로젝트 이름, 기술 스택, 빌드/검증 명령어**로만 한정
- "Do not infer features, product requirements, or functional scope. These are determined by `rw-feature` and `rw-plan`." 금지 조항 추가
- **컨텍스트 모드 분기 추가**:
  - `CONTEXT_READY`: 최소 메타데이터만 추론
  - `CONTEXT_EMPTY`(빈/템플릿 프로젝트): 목적/스택/검증 추론 자체를 수행하지 않음

**2. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — Step 2 기본값 단순화**
- 현재 Goal/Scope/Constraints 기본값 3가지를 제거
- 대신: `Project name default: infer from package manifest or directory name` 정도로 경량화

**3. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — Step 3 PLAN.md 내용 제한**
- "concise PRD" 표현을 제거 → "workspace metadata skeleton"으로 변경
- PLAN.md 초기 내용을 엄격히 정의:
  - `# <프로젝트명>` (1줄)
  - `## 개요`
    - `CONTEXT_READY`: 프로젝트 목적 요약 1~3줄 + 기술 스택/검증 명령어 요약
    - `CONTEXT_EMPTY`: "목적 미정/스택 미정/다음 단계는 rw-feature" placeholder 1~3줄
  - `## Feature Notes (append-only)` (빈 섹션, 항목 없음)
- **명시적 금지**: 기능 요구사항, 데이터 모델, 명령어 목록, 코딩 규칙, 프로젝트 구조 등의 상세 내용 작성 금지
- Step 3의 `assumptions/defaults used` 기록도 제거 (init이 inference를 거의 하지 않으므로 불필요)

**4. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — Step 4 TASK-01 제한 강화**
- 기존 "exactly 1 bootstrap task" 텍스트를 **최상위 Critical 규칙으로 승격**
- `Quick summary` 바로 아래 또는 Steps 앞에 별도 "Critical constraints" 블록 추가:
  ```
  Critical constraints (never override):
  - TASK file limit: create AT MOST 1 task file (TASK-01-bootstrap-workspace.md). 
    Creating 2 or more task files during rw-init is a violation.
  - Feature decomposition is FORBIDDEN in rw-init. 
    Task decomposition belongs exclusively to rw-plan-lite / rw-plan-strict.
  ```
- Step 4 본문에서도 "create exactly 1 bootstrap task" 유지하되, 부정 예시 추가: "Do NOT create TASK-02, TASK-03, etc."

**5. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — Step 5 PROGRESS.md 경량화**
- **신규 워크스페이스**에서는 bootstrap 결과에 맞춰 최소 행만 생성
- **기존 PROGRESS.md가 있으면 절대 재작성하지 않고 기존 행/로그를 보존**
- 누락된 TASK row만 `pending`으로 추가하도록 명시(append-only 보정)
- 로그도 "Initial workspace scaffolded." 한 줄로 제한

**6. [rw-init.prompt.md](.github/prompts/rw-init.prompt.md) — 역할 경계 명시 섹션 추가**
- Steps 전에 "Responsibility boundary" 블록 신설:
  | Stage | Responsibility |
  |-------|---------------|
  | `rw-init` | 인프라 스캐폴딩만 (CONTEXT, PLAN 뼈대, PROGRESS 뼈대, TASK-01) |
  | `rw-feature` | 기능 정의 (feature 스펙 파일 작성) |
  | `rw-plan` | 기능 → 태스크 분해 (TASK-XX 생성, PLAN Feature Notes, PROGRESS 갱신) |
  | `rw-run` | 태스크 구현 (제품 코드 작성) |

**7. [rw-feature.prompt.md](.github/prompts/rw-feature.prompt.md) — 확인 및 소규모 조정**
- 현재 역할 분리가 잘 되어 있음 (`PLAN.md`, `PROGRESS.md`, `tasks/*` 수정 금지 규칙 존재)
- 변경 최소화: "Rules" 섹션에 "rw-feature does not create TASK files or modify PROGRESS.md" 명시 확인만

**8. [rw-plan-lite.prompt.md](.github/prompts/rw-plan-lite.prompt.md) / [rw-plan-strict.prompt.md](.github/prompts/rw-plan-strict.prompt.md) — 최소 PLAN.md 대응**
- init이 PLAN.md를 경량으로 만들면, plan이 `## Feature Notes (append-only)`에 첫 항목을 추가하게 됨
- 소규모 조정:
  - `.ai/PLAN.md`가 없으면 최소 skeleton을 자동 생성 후 진행
  - `.ai/PROGRESS.md`가 없으면 최소 템플릿을 생성 후 진행
  - PLAN `개요`가 간략해도 정상 동작함을 전제 조건에 명시

**9. [rw-run-lite.prompt.md](.github/prompts/rw-run-lite.prompt.md) — 확인**
- SUBAGENT_PROMPT가 `PLAN.md`를 참조하지만, 실제 구현은 TASK 파일 기반이므로 PLAN.md가 간략해도 문제없음
- 변경 불필요

**10. [CONTEXT.md](.ai/CONTEXT.md) — 역할 경계 문서화**
- `## 프롬프트 작성 규칙` 또는 새 `## 오케스트레이션 역할 경계` 섹션에 단계별 책임 매트릭스 추가
- 각 프롬프트가 Step 0에서 CONTEXT.md를 읽으므로, 여기에 역할 경계를 명시하면 모든 프롬프트가 참조 가능

**11. 문서/템플릿 안내 동기화**
- [README.md](README.md), [.ai/GUIDE.md](.ai/GUIDE.md), [scripts/extract-template.sh](scripts/extract-template.sh)의 `rw-init` 설명을 스캐폴딩 중심으로 통일
- `rw-init`는 "프로젝트 목적 짧은 요약 + 뼈대 파일 준비"까지만 수행하고, 기능 정의/분해는 후속 단계 책임임을 명시

**12. [.github/prompts/rw-new-project.prompt.md](.github/prompts/rw-new-project.prompt.md) 추가**
- `rw-init -> rw-discovery` 통합 프롬프트를 신설(`rw-new-project`)
- 역할:
  - `.ai` 스캐폴딩(`CONTEXT`, 최소 `PLAN/PROGRESS`, optional `TASK-01`)
  - 사용자와 Q&A로 프로젝트 방향 확정
  - `PLAN.md` 개요 구체화
  - `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` 생성
- 비역할:
  - `TASK-02+` 생성 금지
  - feature 분해(`features`, `rw-plan`) 책임 침범 금지
- 권장 순서: `rw-new-project` → `rw-feature` → `rw-plan-*` → `rw-run-*`

---

## Verification

1. **새 빈 프로젝트에서 `rw-new-project` 실행** → `.ai/` 디렉토리 확인:
   - CONTEXT.md: 언어 정책 포함
   - PLAN.md: 프로젝트명 + 개요 1~3줄 + 빈 Feature Notes만 존재
   - PROGRESS.md: TASK-01 `pending` 행 1개 + 로그 1줄만 존재
   - tasks/: `TASK-01-bootstrap-workspace.md` 1개만 존재
   - TASK-02 이상의 파일이 없는지 확인
2. **이어서 `rw-feature` 실행** → `.ai/features/` 에 feature 스펙 1개 생성, PLAN/PROGRESS/tasks 미변경
3. **이어서 `rw-plan-lite` 실행** → PLAN.md Feature Notes에 항목 추가, TASK-02~XX 생성, PROGRESS에 행 추가
4. **이어서 `rw-run-lite` 실행** → 태스크 순차 구현
5. **같은 워크스페이스에서 `rw-init` 재실행** → 기존 `PLAN/PROGRESS` 내용이 유지되고 누락 항목만 보정되는지 확인(idempotent)

---

## Decisions

- **PLAN.md에서 PRD 작성 제거**: init 단계에서 상세 PRD를 작성하지 않음. 프로젝트의 기능 정의는 전적으로 `rw-feature` → `rw-plan` 파이프라인에서 수행
- **프로젝트 목적은 최소 요약으로 유지**: init 단계에서도 "이 저장소가 무엇인지"를 잃지 않도록 목적/스택/검증 명령어를 1~3줄 수준으로만 기록
- **빈 프로젝트 추론 금지**: 템플릿만 존재하는 초기 상태에서는 추론 결과를 만들지 않고 명시적 placeholder로 남긴 뒤 `rw-feature`로 사용자 입력을 받도록 전환
- **Critical constraints를 프롬프트 상단으로 승격**: AI가 장문 프롬프트의 중간 제약을 무시하는 문제를 방지하기 위해, 핵심 금지 사항을 Steps 앞에 배치
- **CONTEXT.md에 역할 매트릭스 추가**: 모든 프롬프트가 Step 0에서 읽는 파일이므로, 여기에 경계를 명시하면 단일 진실 원천(single source of truth)으로 기능
