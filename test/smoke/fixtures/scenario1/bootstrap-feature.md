# FEATURE: bootstrap-foundation

Status: READY_FOR_PLAN
Planning Profile: FAST_TEST

## Summary
Hello CLI 앱의 기초 구조를 설정하고 핵심 기능을 구현한다.

## Need Statement
- User: 개발자
- Problem: RW 워크플로우 검증을 위한 최소 프로젝트 필요
- Desired Outcome: `hello greet <name>` 명령이 동작하는 CLI 앱
- Acceptance Signal: `npm run build` 성공 및 출력 확인

## Goal
Node.js + TypeScript + Commander.js 기반 Hello CLI 앱

## In Scope
- package.json, tsconfig.json
- Commander.js CLI 엔트리포인트
- `greet <name>` 명령

## Out of Scope
- 테스트 프레임워크, CI/CD

## Functional Requirements
- `hello greet <name>`: "Hello, <name>!" 출력

## Constraints
- Node.js >= 18, ESM, TypeScript strict

## Acceptance
- `npm run build` exit code 0
- `node dist/index.js greet World` → "Hello, World!"

## Verification Baseline
- `npm run build && node dist/index.js greet World`

## Notes
- source: rw-smoke-test (fixture)
- recommended next: rw-plan
