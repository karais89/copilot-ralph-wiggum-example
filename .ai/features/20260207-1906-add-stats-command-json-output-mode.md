# FEATURE: add-stats-command-json-output-mode

Status: PLANNED

## Summary
`stats` CLI 명령에 `--json` 출력 모드를 추가해 기계가 읽기 쉬운 통계를 제공한다.

## User Value
- 사용자와 자동화 스크립트가 JSON 기반으로 통계를 파싱하여 다른 도구/대시보드와 쉽게 연동할 수 있다.

## Goal
- 기존 `stats`의 사람 친화 출력은 유지하고, `--json` 사용 시 안정적인 JSON 스키마를 제공한다.

## In Scope
- 기존 `stats` 명령에 `--json` 플래그를 추가한다.
- 출력 JSON의 최소 스키마(카운트, 카테고리, 타임스탬프 등)를 정의하고 문서화한다.
- 변경 후 `npm run build`가 통과하도록 보장한다.
- JSON 출력 생성에 대한 단위 테스트를 추가한다.

## Out of Scope
- 원격 서버 전송 등 텔레메트리 파이프라인/외부 통합 구현
- 명령 파서 라이브러리 대규모 리팩터링

## Functional Requirements
- `stats --json` 실행 시 stdout에 유효한 JSON을 출력하고 성공 시 exit code 0을 반환한다.
- JSON 스키마는 최소 `total`, `completed`, `pending`, `overdue`(숫자), `generated_at`(ISO-8601 문자열)을 포함한다.
- `--json`이 없을 때 기존 사람 친화 출력 동작은 변경되지 않는다.
- 내부 오류 시 `stats --json`은 `error`, `message` 필드를 가진 JSON을 출력하고 non-zero exit code를 반환한다.

## Constraints
- 하위 호환성: `--json` 미사용 시 기존 `stats` 동작을 유지한다.
- 최소 범위: 사용자 요구를 만족하는 필수 필드 중심으로만 스키마를 구현한다.
- 빌드 요구사항: 변경 후 `npm run build`가 통과해야 한다.

## Acceptance
- `node dist/index.js stats --json`(또는 동등한 개발 명령) 실행 시 스키마에 맞는 파싱 가능한 JSON이 출력된다.
- `node dist/index.js stats` 실행 시 기존 사람 친화 출력이 유지된다.
- JSON 정상/오류 출력 케이스를 테스트로 검증하고, 로컬 `npm test`가 통과한다.
- JSON 오류 응답에 명확한 오류 메시지가 포함된다.

## Edge Cases and Error Handling
- 데이터 소스 일부가 불가한 경우, 가능한 범위의 숫자 값을 포함하고 `partial: true` 플래그를 추가한다.
- 예기치 못한 예외 발생 시 `{ "error": "internal", "message": "..." }` 형식 JSON을 출력하고 non-zero로 종료한다.
- `--json`과 다른 출력 옵션이 동시에 들어오면 JSON 모드를 우선 적용한다.

## Verification Baseline
- JSON 키/타입(`total`, `completed`, `pending`, `overdue`, `generated_at`) 검증 단위 테스트를 작성한다.
- 문서에 예시 JSON을 추가하고 `JSON.parse` 기반 간단한 통합 테스트를 포함한다.

## Risks and Open Questions
- 향후 필드 확장을 위한 스키마 진화 전략(`version` 또는 `schema_version`)을 어떻게 둘지 결정이 필요하다. 향후 변경이 예상되면 `schema_version` 추가를 권장한다.
- `generated_at` 시간대 기준을 UTC로 통일할지 결정이 필요하다(권장: UTC ISO-8601).

## Notes
- source: rw-feature
- created: 2026-02-07 19:06:00
- recommended next step: rw-plan-lite
 - plan_tasks: TASK-14~TASK-17 planned 2026-02-07

## Implementation Notes
- `src/commands/stats.ts` now emits `total`, `completed`, `pending`, `overdue` (number), and `generated_at` (ISO-8601 string) when `--json` is used.
- On error and when `--json` is requested, the CLI emits `{ "error": "internal", "message": "..." }` and exits non-zero.
