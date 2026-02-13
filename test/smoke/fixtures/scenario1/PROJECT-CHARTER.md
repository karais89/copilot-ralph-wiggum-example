# Project Charter — Hello CLI

## Summary
터미널에서 사용자 이름을 받아 인사 메시지를 출력하는 간단한 CLI 앱.

## MVP In Scope
- `hello greet <name>` 명령
- TypeScript 빌드 체인

## Constraints
- Node.js >= 18, ESM, TypeScript strict

## Verification Baseline
- `npm run build && node dist/index.js greet World`
