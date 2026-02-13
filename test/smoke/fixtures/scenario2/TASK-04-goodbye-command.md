# TASK-04: goodbye 명령 추가

## Dependencies
- TASK-03

## Description
기존 CLI에 `hello goodbye <name>` 명령을 추가한다.

## Acceptance Criteria
- `npm run build` exit code 0
- `node dist/index.js goodbye World` → "Goodbye, World!" 출력
- 기존 `greet` 명령 정상 동작

## Files to Create/Modify
- src/index.ts

## Verification
- `npm run build && node dist/index.js goodbye World`
