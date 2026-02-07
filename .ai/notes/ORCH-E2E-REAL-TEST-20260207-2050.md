# 오케스트레이션 E2E 실행 기반 테스트 결과

- **테스트 일시**: 2026-02-07 20:47~21:00 (KST)
- **테스트 브랜치**: `test/orch-e2e-real-20260207-2047`
- **기반 커밋**: `721d729` (main)
- **대상 프롬프트**: `rw-feature`, `rw-plan-strict`, `rw-run-strict`, `rw-archive`

---

## 시나리오 종합

| # | 시나리오 | 결과 | 판정 근거 |
|---|----------|------|-----------|
| 1 | 정상 흐름: feature→plan→run 완료 | **PASS** | 3개 태스크 생성·구현·완료, build=0 |
| 2 | READY 없음: plan이 즉시 중단 | **PASS** | `FEATURE_NOT_READY` 출력 확인 |
| 3 | READY 2개 이상: plan이 즉시 중단 | **PASS** | `FEATURE_MULTI_READY` 출력 확인 |
| 4 | archive 트리거: PAUSE→archive→재개 | **PASS** | 8158→664B, archive 파일 생성, 재개 정상 |
| 5 | review 3회 실패: ESCALATE 중단 | **PASS** | `🛑` 중단 메시지 정확 출력 |
| 6 | escalated 복구: RESOLVED 후 재개 | **PASS** | Step 7 통과, 루프 재개 가능 확인 |

---

## 시나리오 1: 정상 흐름 (feature → plan → run 완료)

### 재현 절차
1. `rw-feature` 로직으로 `.ai/features/20260207-2048-e2e-test-list-filter.md` 생성 (`Status: READY_FOR_PLAN`)
2. `rw-plan-strict` 로직 실행: READY 1개 감지, TASK-18~20 생성, PLAN.md/PROGRESS.md 갱신, feature → PLANNED
3. `rw-run-strict` 루프 진입: PAUSE/LOCK/ESCALATE 없음, pending 3개 감지
4. subagent로 TASK-18(list 필터), TASK-19(CLI 등록), TASK-20(통합 검증) 순차 구현

### 실행 증거

**TASK-18 (list 필터 플래그 추가)**
- 명령: `npm run build` → exit 0
- 커밋: `9c277ff feat(list): add completed/pending filter flags`
- 변경: `src/commands/list.ts` (ListOptions 인터페이스 + filterTodos 헬퍼)

**TASK-19 (CLI 옵션 등록)**
- 명령: `npm run build` → exit 0, `npm run dev -- list --help` → `-c, --completed` / `-p, --pending` 표시
- 커밋: `88c4901 feat(list): wire --completed/--pending CLI options`
- 변경: `src/index.ts` (Commander option 추가)

**TASK-20 (통합 검증)**
- 명령: `npm run build` → exit 0
- 테스트: add 2개 → done 1개 → `list --completed`(완료만) → `list --pending`(미완료만) → `list`(전체)
- 커밋: `14a4f0e test(list): verify filter integration e2e`
- 모든 필터 조합 정확 동작 확인

**최종 상태**: TASK-18~20 모두 `completed`, PROGRESS에 로그 기록, `npm run build` 통과

---

## 시나리오 2: READY 없음 → FEATURE_NOT_READY

### 재현 절차
1. 모든 feature 파일 상태 확인: `DRAFT` 또는 `PLANNED` (READY_FOR_PLAN 없음)
2. `rw-plan-strict` Feature Input Resolution 실행

### 실행 증거
```
Step 2: .ai/features/ exists? YES
Step 3: candidates: 3개 (20260207-1905, 20260207-1906, 20260207-2048)
Step 5: READY_FOR_PLAN files: (없음)
READY_COUNT=0
FEATURE_NOT_READY
Fix: open the latest YYYYMMDD-HHMM-<slug>.md and change Status to READY_FOR_PLAN
```
- `grep -rl "^Status: READY_FOR_PLAN$"` 결과: 0개 → `FEATURE_NOT_READY` 즉시 출력
- 후속 작업 없이 즉시 중단 확인

---

## 시나리오 3: READY 2개 이상 → FEATURE_MULTI_READY

### 재현 절차
1. `20260207-1905-feature-draft.md` → `Status: READY_FOR_PLAN` 변경
2. `20260207-2050-e2e-test-multi-ready.md` 신규 생성 (`Status: READY_FOR_PLAN`)
3. `rw-plan-strict` Feature Input Resolution 실행

### 실행 증거
```
READY_FOR_PLAN files:
  .ai/features/20260207-2050-e2e-test-multi-ready.md
  .ai/features/20260207-1905-feature-draft.md
READY_COUNT=2
FEATURE_MULTI_READY
Fix: keep exactly one file as READY_FOR_PLAN, set others to DRAFT or PLANNED
```
- 2개 READY 감지 → `FEATURE_MULTI_READY` 즉시 출력
- 후속 작업 없이 즉시 중단 확인
- 정리: 테스트 파일 삭제, draft 파일 `DRAFT`로 복원

---

## 시나리오 4: archive 트리거 → PAUSE → archive → 재개

### 재현 절차
1. PROGRESS 상태 확인: 8158B (>8000), completed 20행
2. `rw-run-strict` Loop Step 6 → archive 트리거 감지
3. `.ai/PAUSE.md` 생성
4. `rw-archive` 로직 실행:
   - PAUSE 존재 확인 ✅ / ARCHIVE_LOCK 없음 ✅
   - ARCHIVE_LOCK 생성
   - `progress-archive/STATUS-20260207-2050.md` (20 completed rows) 생성
   - `progress-archive/LOG-20260207-2050.md` (전체 로그) 생성
   - PROGRESS.md 슬림화: active tasks만 + REVIEW 로그 보존
   - ARCHIVE_LOCK 삭제
5. PAUSE.md 삭제 → run-strict 재개

### 실행 증거
```
Archive 전: Size=8158 Completed=20
Archive 후: Size=664 Completed=0
ARCHIVE_LOCK deleted
Archive files: LOG-20260207-2050.md  STATUS-20260207-2050.md
Archive 내 TASK ID: 20개 (sort -u)
PAUSE removed → NO PAUSE, NO LOCK
```
- PROGRESS 92% 감량 (8158→664B)
- 모든 20개 completed TASK가 STATUS archive에 보존
- REVIEW_FAIL TASK-17 로그 active PROGRESS에 보존 (archive 규칙 준수)
- PAUSE/LOCK 정상 제거 후 재개 가능

---

## 시나리오 5: review 3회 실패 → REVIEW-ESCALATE 중단

### 재현 절차
1. PROGRESS에 TASK-21 pending 행 추가
2. REVIEW_FAIL TASK-21 (1/3), (2/3), REVIEW-ESCALATE TASK-21 (3/3) 로그 주입
3. `rw-run-strict` Loop Step 7 실행

### 실행 증거
```
REVIEW-ESCALATE TASK-21 (3/3): manual intervention required
🛑 A task failed review 3 times. Manual intervention required.
ESCALATE_DETECTED=YES
```
- `grep "REVIEW-ESCALATE" | grep -v "RESOLVED" | grep -v "REVIEW_FAIL"` → 1건 감지
- 오케스트레이터 루프 즉시 중단

---

## 시나리오 6: REVIEW-ESCALATE-RESOLVED 후 재개

### 재현 절차
1. PROGRESS Log에 `REVIEW-ESCALATE-RESOLVED TASK-21: <해결 요약>` append
2. `rw-run-strict` Loop Step 7 재실행

### 실행 증거
```
Escalate entries:
  REVIEW-ESCALATE TASK-21 (3/3): manual intervention required
Resolved entries:
  REVIEW-ESCALATE-RESOLVED TASK-21: E2E 테스트 수동 개입 완료, 로직 수정 반영
ESCALATE_BLOCKED=NO
No unresolved REVIEW-ESCALATE entries. Loop may proceed.
```
- TASK별 ESCALATE/RESOLVED 매칭 로직 정상 작동
- RESOLVED 존재 시 해당 TASK의 escalate 해제, 루프 재개 가능

---

## 원인 분석 및 teardown 보강

### 원인
- 시나리오 5/6 재현을 위해 `PROGRESS`에 `TASK-21` 행과 REVIEW 로그를 수동 주입했다.
- 테스트 종료 시 teardown을 수행하지 않아 synthetic `TASK-21`이 `pending`으로 잔존했다.
- `TASK-21`은 `.ai/tasks/TASK-21-*.md` 파일이 없어, 운영 루프 기준으로는 고아 상태였다.

### 조치
- active `PROGRESS`에서 synthetic `TASK-21` 행과 시나리오용 REVIEW 주입 로그를 정리했다.
- 운영 로그 연속성을 위해 cleanup 사실은 단일 teardown 로그로 남겼다.

### 재발 방지 체크리스트 (E2E 종료 직후)
1. `Task Status`의 모든 `pending/in-progress` 행이 실제 `.ai/tasks/TASK-*.md` 파일과 1:1로 매칭되는지 확인
2. 시나리오 주입용 synthetic TASK/REVIEW 로그를 제거 또는 별도 테스트 브랜치에서만 유지
3. `rw-run-strict` 재개 전 `PAUSE/ARCHIVE_LOCK` 부재와 unresolved `REVIEW-ESCALATE` 부재를 확인

---

## 잔여 리스크

| 리스크 | 심각도 | 비고 |
|--------|--------|------|
| `runSubagent` 미지원 환경 fallback | Low | 본 E2E에서는 실제 runSubagent로 검증. `MANUAL_FALLBACK_REQUIRED` 토큰 경로는 미테스트 |
| REVIEW_FAIL count 계산 시 archive된 로그 교차 참조 | Low | 프롬프트 규칙상 REVIEW 로그는 archive하지 않으므로 active에서만 카운트 가능. 단, 매우 긴 프로젝트에서 로그가 과도하게 커질 수 있음 |
| 동시 실행 방지 | Medium | ARCHIVE_LOCK/PAUSE 기반 동시성 제어는 파일 기반이므로 race condition 가능성 존재 (실무에서 발생 확률 낮음) |
| feature input resolution의 grep 정규식 | Low | `Status: READY_FOR_PLAN`이 줄 중간에 나올 경우 오탐 가능. `^Status: READY_FOR_PLAN$` 패턴으로 검증 필요 |
| PROGRESS 사이즈 기반 archive 트리거 | Low | 한국어 멀티바이트 문자로 인해 동일 행 수라도 바이트 수가 영어보다 클 수 있음. 현행 8000B 임계값은 충분한 여유 있음 |

---

## 변경 파일 목록 (테스트 브랜치)

```
 .ai/PLAN.md                                        |  1 +
 .ai/PROGRESS.md                                    |  7 +++
 .ai/features/20260207-2048-e2e-test-list-filter.md | 50 +++
 .ai/tasks/TASK-18-list-filter-flags.md             | 23 +++
 .ai/tasks/TASK-19-wire-list-filter-cli.md          | 21 +++
 .ai/tasks/TASK-20-list-filter-integration.md       | 22 +++
 src/commands/list.ts                               | 44 +++
 src/index.ts                                       |  8 +-
```

커밋 이력:
- `14a4f0e test(list): verify filter integration e2e`
- `88c4901 feat(list): wire --completed/--pending CLI options`
- `9c277ff feat(list): add completed/pending filter flags`
