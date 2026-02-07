# Features 폴더 사용법

`rw-plan-lite` / `rw-plan-strict`는 아래 규칙으로 feature 파일을 읽습니다.

1. 후보 파일: `.ai/features/*.md` 중 `FEATURE-TEMPLATE.md`, `README.md` 제외
2. 필수 상태 라인: `Status: READY_FOR_PLAN`
3. 후보가 여러 개면 파일명 사전순 마지막(최신) 1개 선택
4. 에러 처리:
   - 폴더 없음/읽기 불가: `FEATURES_DIR_MISSING`
   - `.md` 파일 없음: `FEATURE_FILE_MISSING`
   - READY 후보 없음: `FEATURE_NOT_READY`
5. 에러 발생 시:
   - 첫 줄에 에러 토큰 출력
   - 다음 줄부터 즉시 해결 가이드 출력
   - 보완 질문 없이 중단

권장 파일명 형식:

`YYYYMMDD-HHMM-<slug>.md`

예:

`20260207-1930-export-command.md`

상태값 권장 흐름:

- `DRAFT`
- `READY_FOR_PLAN`
- `PLANNED`
- `DONE`
- `BLOCKED`

주의:

- `Status:` 키워드와 상태값은 파싱 규칙이므로 영어 그대로 유지하세요.
