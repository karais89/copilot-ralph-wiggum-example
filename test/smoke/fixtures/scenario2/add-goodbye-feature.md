# FEATURE: add-goodbye-command

Status: READY_FOR_PLAN
Planning Profile: FAST_TEST

## Summary
`hello goodbye <name>` 명령을 추가하여 작별 인사 기능을 구현한다.

## Need Statement
- User: CLI 사용자
- Problem: 작별 인사 기능이 없음
- Desired Outcome: `hello goodbye <name>` → "Goodbye, <name>!" 출력
- Acceptance Signal: `npm run build && node dist/index.js goodbye World`

## Goal
기존 Hello CLI에 goodbye 명령을 추가한다.

## In Scope
- `goodbye <name>` 명령 추가

## Out of Scope
- 기존 greet 명령 변경

## Functional Requirements
- `hello goodbye <name>`: "Goodbye, <name>!" 출력

## Constraints
- 기존 기능 비파괴

## Acceptance
- `npm run build` exit code 0
- `node dist/index.js goodbye World` → "Goodbye, World!"

## Verification Baseline
- `npm run build && node dist/index.js goodbye World`

## Notes
- source: rw-smoke-test (fixture)
