# GitHub Copilot Audit Prompt (RW Workflow: 논리/정합성/실행 신뢰성)

아래 절차를 그대로 수행해라. 목적은 현재 저장소의 RW prompt-driven autonomous workflow에서
**논리 오류 + 실행 신뢰성 리스크**를 찾는 것이다.

원칙:
- 요약보다 결함 리스팅을 우선한다.
- 추측하지 말고 반드시 파일 근거(`파일:라인`)를 붙인다.
- 근거 없는 판단은 `Open Questions`로 분리한다.

검증 대상(기본):
- `.github/prompts/*.prompt.md`
- `README.md`
- `.ai/GUIDE.md`

검증 절차:

## 1) Static Audit
- 단계 책임 경계 충돌 여부:
  - `rw-new-project / rw-doctor / rw-feature / rw-plan-* / rw-run-* / rw-archive`
- 입력/출력 토큰 일관성:
  - `LANG_POLICY_MISSING`, `RW_TARGET_ROOT_INVALID`, `RW_DOCTOR_PASS`, `RW_DOCTOR_BLOCKED`, `RW_ENV_UNSUPPORTED`, `Status`, `READY_FOR_PLAN`, `PLANNED`, `Task Status`, `Log`
- idempotency 규칙 충돌 여부
- 언어 정책 누락/충돌 여부:
  - 운영 프롬프트 본문 영어 유지 규칙
  - 사용자 문서 한국어 기본 규칙
  - parser 토큰 영어 고정 규칙
- task 생성 규칙 충돌 여부:
  - bootstrap `10~20`
  - bootstrap 단순 범위 예외 `5`
  - 일반 feature: Lite `3~6`, Strict `3~8`
  - task 크기 `30~120`분
  - 각 task `Verification` 명령 `>=1`

## 2) Flow Simulation
아래 시나리오를 문서 규칙 기준으로 시뮬레이션해 모순/막힘을 찾는다.
- 빈 프로젝트
- context-ready 프로젝트
- rerun(idempotency) 시나리오
- `rw-run`에서 nested `runSubagent` 위험 잔존 여부
- Top-level 실행 강제 규칙과 `rw-run-*` 진입/중단 규칙 정합성
- `rw-doctor` preflight 결과(`RW_DOCTOR_PASS`/`RW_DOCTOR_BLOCKED`)와 `rw-run-*` 진입 규칙 정합성
- target root invalid 처리(`RW_TARGET_ROOT_INVALID`)와 즉시 중단 규칙 정합성
- target-root 포인터 세트(`.ai/runtime/rw-active-target-id.txt`, `.ai/runtime/rw-targets/<id>.env`, legacy `.ai/runtime/rw-active-target-root.txt`) 규칙 누락/불일치 여부
- `rw-init`/`rw-new-project`에서 포인터 세트 자동 생성·갱신 규칙이 실제 실행 흐름과 맞는지
- 운영 프롬프트가 "계획 문구만 출력하고 실제 단계 실행 없음" 상태에 빠질 위험이 없는지

## 3) 운영 Plausibility Check
운영 프롬프트(`rw-*`) 기준으로:
- 실행 시나리오가 현재 운영 규칙(`rw-*`, GUIDE, README)과 불일치하는 항목
- 실행 순서/상태 전이/판정 조건 모순 여부
- `rw-doctor`의 runSubagent 가용성 판정이 실제 프로브 기반인지(거짓 PASS 방지)

심각도 기준:
- `P0`: 테스트/운영이 즉시 깨지거나 잘못된 성공/실패를 강제
- `P1`: 실제 운용에서 높은 확률로 오동작/정지/책임 경계 침범 유발
- `P2`: 중기적으로 혼란/드리프트/검증 누락을 유발

출력 형식(반드시 준수):
- Critical Findings (심각도 순)
  - [P0/P1/P2] 제목
  - 파일:라인
  - 왜 문제인지
  - 재현 방법
  - 수정 제안(짧게)
- Open Questions
- 결론: OVERALL PASS/FAIL

중요:
- 문제 없으면 `No critical findings`를 명시하고, 남은 리스크만 적는다.
- 동일 원인의 중복 항목은 하나로 묶고 대표 근거를 제시한다.
