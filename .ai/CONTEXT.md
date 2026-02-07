# 워크스페이스 컨텍스트

## 언어 정책

- 프롬프트 본문 언어(`.github/prompts/*.prompt.md`): 영어(필수)
- 프롬프트 사전 점검: 모든 프롬프트는 수정 전에 `Step 0 (Mandatory)`로 이 파일을 먼저 읽어야 함
- 사용자 문서 언어(`.ai/GUIDE.md`, `.ai/PLAN.md`, `.ai/PROGRESS.md`, `.ai/tasks/*.md`, `.ai/notes/*.md`, `.ai/features/*.md`): 한국어 기본
- 기존(legacy) 문서가 영어인 경우 즉시 전면 번역을 강제하지 않음. 다만 신규 작성/수정 시에는 한국어 우선
- 커밋 메시지 언어: 영어(Conventional Commits)
- 언어 충돌 시: 이 파일 규칙을 우선 적용

## 기계 파싱 토큰 (번역 금지)

아래 값은 오케스트레이션 프롬프트/파서의 계약값이므로 문자열을 그대로 유지해야 합니다.

- `.ai/PROGRESS.md` 섹션 헤더:
  - `## Task Status`
  - `## Log`
- `.ai/PROGRESS.md` 테이블 헤더:
  - `| Task | Title | Status | Commit |`
- `.ai/PROGRESS.md` 상태값:
  - `pending`
  - `in-progress`
  - `completed`
- Task ID 형식:
  - `TASK-XX` (0-padding 숫자 ID)
- 리뷰 로그 마커:
  - `REVIEW_FAIL`
  - `REVIEW-ESCALATE`
- 프롬프트 사전 점검 오류 토큰:
  - `LANG_POLICY_MISSING`
- feature 파일 입력 오류 토큰:
  - `FEATURES_DIR_MISSING`
  - `FEATURE_FILE_MISSING`
  - `FEATURE_NOT_READY`
  - `FEATURE_MULTI_READY`
  - `FEATURE_SUMMARY_MISSING`
- fallback 출력 토큰:
  - `MANUAL_FALLBACK_REQUIRED`
- 파일/경로 계약:
  - `.ai/PAUSE.md`
  - `.ai/ARCHIVE_LOCK`
  - `.ai/progress-archive/STATUS-*.md`
  - `.ai/progress-archive/LOG-*.md`
  - `.ai/PLAN.md`의 `## Feature Notes (append-only)`

## 프롬프트 작성 규칙

1. 프롬프트 본문은 주 언어 1개만 유지하고 라인 단위 혼용을 피한다.
2. 모든 프롬프트에 `Step 0 (Mandatory)`를 두고 `.ai/CONTEXT.md`를 먼저 읽는다.
3. `.ai/CONTEXT.md`를 읽을 수 없으면 `LANG_POLICY_MISSING`으로 즉시 중단한다.
4. 출력/리포트는 섹션 단위로 언어를 통일한다.

## 추가 가드레일

1. 한국어 설명은 허용되지만, 기계 파싱 토큰 자체는 절대 변경하지 않는다.
2. 문서를 번역하더라도 `Task Status`, `Log`, 상태 enum 값은 이름을 바꾸지 않는다.
3. append-only 원칙 유지:
   - `.ai/PLAN.md`: `Feature Notes`에만 append
   - `.ai/PROGRESS.md` Log: archive 전까지 append 중심으로 유지
4. 실행/아카이브 안전 규칙:
   - 동일 워크스페이스에서 오케스트레이터 동시 실행 금지
   - `rw-archive`는 `.ai/PAUSE.md`가 있는 상태에서만 실행
   - `rw-archive` 실행 시 `.ai/ARCHIVE_LOCK`를 사용해 동시 archive를 방지
5. `runSubagent` 미지원 환경에서는 즉시 종료하지 않고 수동 fallback 절차를 출력한 뒤 안전 중지한다.
