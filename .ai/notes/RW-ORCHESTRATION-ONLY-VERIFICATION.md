# RW Orchestration-Only Verification Report

**일자**: 2026-02-07
**범위**: Ralph Wiggum 오케스트레이션 기법 자체 검증 (제품 코드 평가 제외)
**대상**: 프롬프트 7개, 문서 5개, feature/task 파일 전체

---

## 1. Executive Summary

| 등급 | 건수 |
|------|------|
| P1 (Critical) | 0 |
| P2 (High) | 2 |
| P3 (Medium/Low) | 3 |

**Final Verdict: 조건부 배포 가능** (P2 수정 필수, 아래 필수 수정 목록 참조)

---

## 2. Critical Findings (P1)

**없음.**

---

## 3. High Findings (P2)

### P2-1: rw-run-lite Step 4 — 아카이브 후 완료 태스크 재등록 버그

| 항목 | 내용 |
|------|------|
| **파일** | `.github/prompts/rw-run-lite.prompt.md` L42 |
| **규칙** | `4) Scan TASK-*.md in <TASKS> and append missing task rows to the Task Status table in <PROGRESS> as pending` |
| **문제** | Lite의 step 4는 active PROGRESS 테이블만 검사한다. `rw-archive` 실행 후 completed 행이 `.ai/progress-archive/STATUS-*.md`로 이동되면, 해당 TASK ID가 active PROGRESS에서 사라지므로 **이미 완료된 태스크가 `pending`으로 재등록**된다. |
| **비교** | rw-run-strict L43-45는 "active Task Status table + every `.ai/progress-archive/STATUS-*.md`" 모두를 검사하여 이 문제가 없다. |
| **영향** | 아카이브 후 Lite 루프 재개 시 완료 태스크 재구현 → 불필요한 중복 작업 + 잠재 충돌 |
| **수정안** | rw-run-lite step 4에 rw-run-strict와 동일한 아카이브 파일 체크 로직 추가: `add as pending only task IDs that are missing from both: active Task Status table in <PROGRESS> AND every .ai/progress-archive/STATUS-*.md file (glob)` |

### P2-2: REVIEW-ESCALATE 복구 경로 미문서화

| 항목 | 내용 |
|------|------|
| **파일** | `.github/prompts/rw-run-strict.prompt.md` L49 |
| **규칙** | `7) If <PROGRESS> Log contains REVIEW-ESCALATE, print "🛑 ..." and stop` |
| **문제** | 이 검사는 **로그 전체에서 `REVIEW-ESCALATE` 문자열 존재 여부**만 확인한다. 수동 개입으로 문제를 해결한 뒤에도 기존 `REVIEW-ESCALATE` 행이 로그에 남아 있으므로, 오케스트레이터 재실행 시 **무조건 L49에서 중단**된다. |
| **악화 요인** | `rw-archive.prompt.md` L45: "never move or trim `REVIEW_FAIL` / `REVIEW-ESCALATE` lines from active PROGRESS log" → 아카이브로도 제거 불가. CONTEXT.md L58-60: append-only 원칙 → 직접 삭제도 원칙 위반. |
| **GUIDE 불일치** | `.ai/GUIDE.md` L155: "태스크/요구사항을 수동 수정한 뒤 재실행"이라고 안내하지만, 재실행 시 REVIEW-ESCALATE가 여전히 감지되어 즉시 중단됨. |
| **영향** | REVIEW-ESCALATE 발생 후 documented rules 내에서는 **Strict 루프를 재개할 방법이 없다** (dead-end state). |
| **수정안** | 다음 중 하나를 선택: (a) L49 검사를 "해결되지 않은(active) ESCALATE만 감지"로 변경 (예: `REVIEW-ESCALATE-RESOLVED` append 마커 도입), (b) `.ai/GUIDE.md`/`.ai/CONTEXT.md`에 "수동 해결 후 `REVIEW-ESCALATE-RESOLVED TASK-XX ...` 로그를 append하고 재개" 절차를 명문화, (c) rw-archive에 "resolved escalate만 아카이브" 규칙을 추가. |

---

## 4. Medium/Low Findings (P3)

### P3-1: rw-feature Step 2 자동 생성 템플릿 섹션 불일치

| 항목 | 내용 |
|------|------|
| **파일** | `.github/prompts/rw-feature.prompt.md` L41-42 |
| **문제** | Step 2 자동 생성 템플릿에 나열된 섹션: `Goal`, `Constraints`, `Acceptance`, `In Scope`, `Out of Scope`, `Functional Requirements`, `Edge Cases and Error Handling`, `Verification Baseline`, `Notes` (9개). Step 8 실제 feature 파일 생성 구조(L55-68): `Summary`, `User Value`, `Goal`, `In Scope`, `Out of Scope`, `Functional Requirements`, `Constraints`, `Acceptance`, `Edge Cases and Error Handling`, `Verification Baseline`, `Risks and Open Questions`, `Notes` (12개). **누락**: `Summary`, `User Value`, `Risks and Open Questions`. |
| **영향** | 기존 `FEATURE-TEMPLATE.md`가 존재하면 문제 없음. 새 워크스페이스에서 template 자동 생성 시에만 불일치 발생 (낮은 빈도). |
| **수정안** | Step 2 섹션 목록에 `Summary`, `User Value`, `Risks and Open Questions`를 추가. |

### P3-2: Strict 아카이브 흐름에서 PAUSE.md 자동 생성 모호성

| 항목 | 내용 |
|------|------|
| **파일** | `.github/prompts/rw-run-strict.prompt.md` L48, L85 |
| **문제** | Step 6 아카이브 임계치 도달 시 "Keep `.ai/PAUSE.md` present"라고 출력하고 중단하지만, PAUSE.md를 **실제로 생성하지 않는다**. 이어서 rw-archive를 실행하면 `rw-archive.prompt.md` L29-30에서 PAUSE.md 존재를 검증하고, 없으면 중단한다. 따라서 사용자가 PAUSE.md를 수동 생성해야 하는데, 이 절차가 명확히 안내되지 않았다. |
| **영향** | 사용자 혼란 (낮은 위험). "Keep" 표현이 "이미 있는 것을 유지"로 해석될 수 있으나, 실제로는 아직 없을 수 있음. |
| **수정안** | Step 6 메시지를 "Create `.ai/PAUSE.md` if not present, then run `rw-archive.prompt.md`"로 명확화하거나, 오케스트레이터가 PAUSE.md를 자동 생성한 뒤 중단하도록 변경. |

### P3-3: REVIEW-ESCALATE 후 task status 의미 불일치

| 항목 | 내용 |
|------|------|
| **파일** | `.github/prompts/rw-run-strict.prompt.md` L114 |
| **규칙** | `If prior count is 2 or more: ... keep status unchanged` |
| **문제** | 3회차 리뷰 실패 시 reviewer는 "keep status unchanged" 처리. 이때 implementation subagent가 이미 `completed`로 설정한 상태이므로, **리뷰를 3회 실패한 태스크가 `completed`로 남는다**. 오케스트레이터가 즉시 중단하므로 실질적 피해는 없으나, 의미적으로 부정확. |
| **수정안** | `keep status unchanged` 대신 `revert status to pending` 또는 별도 상태(`escalated`) 도입을 검토. |

---

## 5. Scenario Matrix

### 시나리오 1: 정상 흐름 (rw-feature → rw-plan-strict → rw-run-strict)

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | `.ai/CONTEXT.md` 존재, `.ai/features/` 비어있음 (READY 없음), PLAN/PROGRESS/tasks 존재 |
| **단계** | (1) rw-feature → Step 0 통과 → feature 파일 생성 (`Status: READY_FOR_PLAN`) → (2) rw-plan-strict → Step 0 통과 → READY 1개 감지 → PLAN 업데이트 + TASK 생성 + PROGRESS 갱신 + feature `Status: PLANNED` → (3) rw-run-strict → Step 0 통과 → 루프 진입 → subagent 호출 → reviewer 호출 → 반복 → 완료 |
| **예상 출력** | rw-feature: 파일 경로 + `READY_FOR_PLAN`. rw-plan: task range + `PLANNED`. rw-run: `✅ All tasks completed.` |
| **규칙 근거** | rw-feature L20-68, rw-plan-strict L35-49+L52-76, rw-run-strict L35-55 |
| **판정** | **PASS** |

### 시나리오 2: READY 없음 → rw-plan-strict 즉시 중단

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | `.ai/features/` 존재, 모든 feature 파일이 `Status: DRAFT` 또는 `Status: PLANNED` |
| **예상 출력** | 첫 행: `FEATURE_NOT_READY`, 이어서 수정 가이드, 즉시 중단 (질문 없음) |
| **규칙 근거** | rw-plan-strict feature resolution step 6: "If no READY candidates exist, stop immediately and print: first line exactly: `FEATURE_NOT_READY`", step 10: "In any error case above, stop immediately without clarification questions." |
| **판정** | **PASS** |

### 시나리오 3: READY 2개 → rw-plan-strict 즉시 중단

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | `.ai/features/` 에 2개 이상의 파일이 `Status: READY_FOR_PLAN` |
| **예상 출력** | 첫 행: `FEATURE_MULTI_READY`, 이어서 수정 가이드, 즉시 중단 (질문 없음) |
| **규칙 근거** | rw-plan-strict feature resolution step 7: "If multiple READY candidates exist, stop immediately and print: first line exactly: `FEATURE_MULTI_READY`", step 10: "In any error case above, stop immediately without clarification questions." |
| **판정** | **PASS** |

### 시나리오 4: Strict 아카이브 필요 → 중단 후 rw-archive 수동 호출

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | PROGRESS.md completed 행 > 20 또는 크기 > 8000 chars |
| **예상 출력** | `📦 Manual archive required. Keep .ai/PAUSE.md present, run rw-archive.prompt.md, then resume.` → 중단 |
| **후속 절차** | 사용자가 PAUSE.md 생성 → rw-archive 실행 → ARCHIVE_LOCK 생성 → completed 행/로그 이동 → ARCHIVE_LOCK 삭제 → 사용자가 PAUSE.md 삭제 → 재개 |
| **규칙 근거** | rw-run-strict L48, rw-archive L11+L29-30+L33-35, rw-run-strict L85 |
| **부분 약점** | P3-2 참조: PAUSE.md 자동 생성이 모호함 |
| **판정** | **WARN** (P3-2로 인한 경미한 사용자 혼란 가능) |

### 시나리오 5: Lite 아카이브 필요 → 경고 출력 후 계속

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | PROGRESS.md completed 행 > 20 또는 크기 > 8000 chars |
| **예상 출력** | `⚠️ PROGRESS is growing large. The loop will continue. Recommended: create .ai/PAUSE.md, then run rw-archive.prompt.md manually.` → 루프 지속 |
| **규칙 근거** | rw-run-lite L45, L67: "In Lite mode, archive thresholds produce warnings only; no automatic stop/archive" |
| **부분 약점** | P2-1 참조: 아카이브 실행 후 재개 시 완료 태스크가 재등록될 수 있음 |
| **판정** | **WARN** (아카이브 미실행 시 PASS이나, 실행 후 재개 시 P2-1 발동) |

### 시나리오 6: Review 3회 실패 → REVIEW-ESCALATE 후 중단

| 항목 | 내용 |
|------|------|
| **예상 입력 상태** | PROGRESS Log에 동일 TASK의 `REVIEW_FAIL` 2회 기록 존재, implementation subagent가 해당 TASK 재구현 후 `completed` 설정 |
| **예상 출력** | Reviewer: `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required` 기록, status unchanged(`completed` 유지). 오케스트레이터 다음 루프: L49에서 `REVIEW-ESCALATE` 감지 → `🛑 A task failed review 3 times. Manual intervention required.` → 중단 |
| **규칙 근거** | rw-run-strict REVIEWER_PROMPT step 5 (L108-114), Loop step 7 (L49) |
| **부분 약점** | P2-2: 수동 개입 후 재개 경로가 문서화되지 않음. P3-3: 리뷰 실패 태스크가 `completed`로 남음 |
| **판정** | **WARN** (중단 자체는 정상 동작하나, 복구 경로 미비) |

---

## 6. Contract Consistency Table

### 6-A. Step 0 규칙 일관성

| 프롬프트 | Step 0 존재 | CONTEXT.md 읽기 | LANG_POLICY_MISSING | 수정 전 금지 | 일치 |
|----------|:-----------:|:---------------:|:-------------------:|:------------:|:----:|
| rw-init | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-feature | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-plan-lite | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-plan-strict | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-run-lite | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-run-strict | ✅ | ✅ | ✅ | ✅ | ✅ |
| rw-archive | ✅ | ✅ | ✅ | ✅ | ✅ |

**판정**: 7/7 동일 — **PASS**

### 6-B. 기계 파싱 토큰 보존

| 토큰 | CONTEXT.md 등록 | 프롬프트 사용 | features/*.md 영어 유지 | 일치 |
|------|:---------------:|:------------:|:-----------------------:|:----:|
| `Task Status` | ✅ L15 | rw-run-lite/strict, rw-plan-lite/strict | N/A | ✅ |
| `Log` | ✅ L16 | rw-run-lite/strict, rw-archive | N/A | ✅ |
| `pending` | ✅ L22 | rw-init, rw-plan-lite/strict, rw-run-lite/strict | N/A | ✅ |
| `in-progress` | ✅ L23 | rw-run-lite/strict | N/A | ✅ |
| `completed` | ✅ L24 | rw-run-lite/strict, rw-archive | N/A | ✅ |
| `REVIEW_FAIL` | ✅ L28 | rw-run-strict, rw-archive | N/A | ✅ |
| `REVIEW-ESCALATE` | ✅ L29 | rw-run-strict, rw-archive | N/A | ✅ |
| `LANG_POLICY_MISSING` | ✅ L32 | 7/7 프롬프트 | N/A | ✅ |
| `FEATURES_DIR_MISSING` | ✅ L35 | rw-plan-lite/strict | N/A | ✅ |
| `FEATURE_FILE_MISSING` | ✅ L36 | rw-plan-lite/strict | N/A | ✅ |
| `FEATURE_NOT_READY` | ✅ L37 | rw-plan-lite/strict | N/A | ✅ |
| `FEATURE_MULTI_READY` | ✅ L38 | rw-plan-lite/strict | N/A | ✅ |
| `FEATURE_SUMMARY_MISSING` | ✅ L39 | rw-feature | N/A | ✅ |
| `MANUAL_FALLBACK_REQUIRED` | ✅ L42 | rw-run-lite/strict | N/A | ✅ |
| `.ai/PAUSE.md` | ✅ L44 | rw-run-lite/strict, rw-archive | N/A | ✅ |
| `.ai/ARCHIVE_LOCK` | ✅ L44 | rw-run-lite/strict, rw-archive | N/A | ✅ |
| `Status` (feature 파일) | N/A | rw-feature L28 | `Status: DRAFT` / `READY_FOR_PLAN` / `PLANNED` 영어 유지 | ✅ |
| `READY_FOR_PLAN` | N/A | rw-feature, rw-plan-lite/strict | features/README.md 영어 유지 | ✅ |
| `PLANNED` | N/A | rw-plan-lite/strict | features/README.md 영어 유지 | ✅ |

**판정**: 전체 일치 — **PASS**

### 6-C. Feature 상태 머신

| 전이 | 담당 프롬프트 | 규칙 근거 | 금지 상태 혼입 | 일치 |
|------|:------------:|----------|:--------------:|:----:|
| `DRAFT` → `READY_FOR_PLAN` | rw-feature | rw-feature step 8: `Status: READY_FOR_PLAN` | 없음 | ✅ |
| `READY_FOR_PLAN` → `PLANNED` | rw-plan-lite/strict | rw-plan-lite step 10 / rw-plan-strict step 10 | 없음 | ✅ |
| `DONE` 사용 여부 | - | 전체 검색: 어떤 프롬프트/문서에서도 feature `DONE` 상태 미사용 | 미혼입 | ✅ |
| `BLOCKED` 사용 여부 | - | 전체 검색: 어떤 프롬프트/문서에서도 feature `BLOCKED` 상태 미사용 | 미혼입 | ✅ |

**판정**: 상태 흐름 `DRAFT → READY_FOR_PLAN → PLANNED` 단순화 확인 — **PASS**

### 6-D. READY 선택 규칙

| 조건 | rw-plan-lite | rw-plan-strict | GUIDE | features/README | 일치 |
|------|:------------:|:--------------:|:-----:|:---------------:|:----:|
| 0개 READY → `FEATURE_NOT_READY` | ✅ step 6 | ✅ step 6 | ✅ | ✅ | ✅ |
| 2+개 READY → `FEATURE_MULTI_READY` | ✅ step 7 | ✅ step 7 | ✅ | ✅ | ✅ |
| 1개 READY → 진행 | ✅ step 8 | ✅ step 8 | ✅ | ✅ | ✅ |
| 자동 최신 선택 로직 | 없음 | 없음 | 없음 | 없음 | ✅ |
| 에러 시 질문 금지 | ✅ step 10 | ✅ step 10 | ✅ | ✅ | ✅ |

**판정**: 자동 선택 로직 완전 제거 확인 — **PASS**

### 6-E. Lite vs Strict 분기

| 규칙 | Lite | Strict | 문서 일치 |
|------|------|--------|:--------:|
| Archive 임계치 동작 | 경고만, 계속 (L45, L67) | 중단 + 수동 archive (L48) | GUIDE ✅ |
| Reviewer subagent | 없음 | 있음 (REVIEWER_PROMPT) | GUIDE ✅ |
| REVIEW_FAIL/ESCALATE | 해당 없음 | step 7 (L49) + REVIEWER step 5 | GUIDE ✅ |
| 아카이브 후 task scan | active PROGRESS만 (L42) ⚠️ | active + archive (L43-45) | **불일치 — P2-1** |
| runSubagent fallback | MANUAL_FALLBACK (L50-58) | MANUAL_FALLBACK + review (L55-67) | GUIDE ✅ |

### 6-F. 문서-프롬프트 정합성

| 규칙 | GUIDE/CONTEXT 설명 | 실제 프롬프트 | 일치 |
|------|-------------------|-------------|:----:|
| Lite archive 경고만 | GUIDE "경고를 출력하지만 실행은 계속" | rw-run-lite L45+L67 | ✅ |
| Strict archive 중단 | GUIDE "archive는 rw-archive 수동 실행" | rw-run-strict L48 | ✅ |
| Feature 입력 무인자 | GUIDE "입력 인자 없이 .ai/features/*.md만" | rw-plan-lite/strict frontmatter | ✅ |
| runSubagent fallback | GUIDE "자동 오케스트레이션 루프를 즉시 중지" | rw-run-lite L50+ / rw-run-strict L55+ | ✅ |
| REVIEW-ESCALATE 복구 | GUIDE L155 "수동 수정 뒤 재실행" | rw-run-strict L49: 무조건 중단 | **불일치 — P2-2** |
| TEMPLATE 구조 ↔ rw-feature | FEATURE-TEMPLATE (12섹션) | rw-feature step2 (9섹션) / step8 (12섹션) | **P3-1** |
| CONTEXT 토큰 ↔ 프롬프트 토큰 | CONTEXT 기계 파싱 토큰 전체 | 모든 프롬프트에서 동일 사용 | ✅ |

---

## 7. Final Verdict

### 조건부 배포 가능

P1 이슈가 없으므로 배포 보류는 아니나, **P2 2건**이 존재하여 무조건 배포는 불가합니다.

#### 필수 수정 목록 (배포 전 반드시 해결)

| ID | 수정 내용 | 영향 범위 |
|----|----------|----------|
| **P2-1** | `rw-run-lite.prompt.md` step 4에 `progress-archive/STATUS-*.md` 체크 로직 추가 | rw-run-lite |
| **P2-2** | REVIEW-ESCALATE 복구 절차를 (a) rw-run-strict에 해결 마커 도입, 또는 (b) `.ai/GUIDE.md`/`.ai/CONTEXT.md`에 명시적 복구 단계 추가로 문서화 | rw-run-strict, .ai/GUIDE.md, .ai/CONTEXT.md |

#### 권장 수정 (배포 후 가능)

| ID | 수정 내용 |
|----|----------|
| P3-1 | rw-feature step 2 템플릿 섹션에 `Summary`, `User Value`, `Risks and Open Questions` 추가 |
| P3-2 | rw-run-strict step 6 메시지에서 PAUSE.md 생성 절차를 명확화 |
| P3-3 | REVIEW-ESCALATE 시 task status 처리를 `completed` 유지 대신 `pending` 또는 별도 상태로 변경 |

---

*이 보고서는 모든 대상 파일을 읽기 기반으로 분석한 결과이며, 제품 코드(src, dist, data) 평가는 포함하지 않습니다. 모든 근거는 파일 경로와 줄번호로 추적 가능합니다.*
