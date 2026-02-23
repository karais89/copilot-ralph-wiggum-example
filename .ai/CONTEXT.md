# 워크스페이스 컨텍스트

## 언어 정책

- 운영 프롬프트 본문(`.github/prompts/rw-*.prompt.md`): 영어 유지(필수)
- 사용자 문서(`.ai/*`, `PLAN/PROGRESS/tasks/notes/features`): 한국어 기본
- 커밋 메시지: 영어 Conventional Commit
- 모든 운영 프롬프트는 `Step 0 (Mandatory)`에서 이 파일을 먼저 읽어야 함

## 기계 파싱 토큰 (번역 금지)

아래 토큰은 문자열 그대로 유지한다.

- PROGRESS 섹션/헤더
  - `## Task Status`
  - `## Log`
  - `| Task | Title | Status | Commit |`
  - `pending`
  - `in-progress`
  - `completed`
- Task ID
  - `TASK-XX`
- 태스크 파일 헤더
  - `Title`
  - `Dependencies`
  - `Description`
  - `Acceptance Criteria`
  - `Files to Create/Modify`
  - `Test Strategy`
  - `Verification`
- 리뷰/검증 로그 토큰
  - `REVIEW_OK`
  - `REVIEW_FAIL`
  - `REVIEW-ESCALATE`
  - `REVIEW-ESCALATE-RESOLVED`
  - `REVIEW_FINDING`
  - `REVIEW_ISSUE`
  - `VERIFICATION_EVIDENCE`
- 공통 오류/가드 토큰
  - `LANG_POLICY_MISSING`
  - `FEATURES_DIR_MISSING`
  - `FEATURE_FILE_MISSING`
  - `FEATURE_NOT_READY`
  - `FEATURE_MULTI_READY_AUTOSELECTED`
  - `FEATURE_SUMMARY_MISSING`
  - `FEATURE_NEED_INSUFFICIENT`
  - `MISSING_FIELDS=...`
  - `PROJECT_IDEA_MISSING`
- 경로 계약
  - `.ai/PAUSE.md`
  - `.ai/ARCHIVE_LOCK`
  - `.ai/progress-archive/STATUS-*.md`
  - `.ai/progress-archive/LOG-*.md`
  - `.ai/PLAN.md`의 `## Feature Notes (append-only)`

## 역할 경계

- `rw-new-project`
  - 신규/빈 저장소용 초기 스캐폴딩 + 의도 정리 + bootstrap feature seed 생성
  - 태스크 분해는 하지 않음
- `rw-onboard-project`
  - 기존 코드베이스 온보딩(스냅샷/베이스라인 정리)
  - 기본 handoff는 `rw-feature`
- `rw-feature`
  - `.ai/features/*.md`에 `Status: READY_FOR_PLAN` feature 1개 생성
- `rw-plan`
  - feature를 `TASK-XX`로 분해
  - `PLAN Feature Notes` append + `PROGRESS` pending 동기화
- `rw-run`
  - 구현 루프/검증 실행
  - 한 dispatch당 한 task 완료 불변식 유지
- `rw-review`
  - 배치 리뷰 실행 (`REVIEW_OK`/`REVIEW_FAIL`/`REVIEW-ESCALATE`)
- `rw-archive`
  - 수동 아카이브 (`.ai/PAUSE.md` 필요, `ARCHIVE_LOCK` 사용)

## 추가 가드레일

1. 기계 파싱 토큰은 한국어로 번역하지 않는다.
2. `PLAN.md`는 `Feature Notes` append-only 원칙을 지킨다.
3. `PROGRESS.md` Log는 archive 전까지 append 중심으로 유지한다.
4. 동일 워크스페이스에서 오케스트레이터 동시 실행을 금지한다.
5. `REVIEW-ESCALATE TASK-XX ...`를 수동 해결했으면 `REVIEW-ESCALATE-RESOLVED TASK-XX: ...`를 Log에 남기고 `rw-run`을 재실행한다.
