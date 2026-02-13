# TASK-03: CLI greet 명령

## Dependencies
- TASK-02

## Description
Commander.js를 사용하여 `hello greet <name>` 명령을 구현한다.

## Acceptance Criteria
- `npm run build` exit code 0
- `node dist/index.js greet World` → "Hello, World!" 출력
- `node dist/index.js --help` → 도움말 출력

## Files to Create/Modify
- src/index.ts

## Verification
- `npm run build && node dist/index.js greet World`
