# FEATURE: export-csv-command

Status: PLANNED
Planning Profile: STANDARD

## Summary

`todo export` 명령을 추가해 전체 todo 목록을 CSV 파일로 저장한다.

## Need Statement

- **User**: Todo CLI 앱 사용자 (터미널에서 할 일을 관리하는 개발자/일반 사용자)
- **Problem**: 현재 todo 목록을 스프레드시트·외부 도구와 공유하거나 데이터를 분석하기 어렵다.
- **Desired Outcome**: `todo export [파일명]` 명령 하나로 전체 todo 목록이 CSV 파일로 생성되어 스프레드시트에서 바로 열 수 있다.
- **Acceptance Signal**: `todo export todos.csv` 실행 후 지정 경로에 유효한 CSV 파일이 생성되고, 열 이름(id, title, completed, createdAt)이 포함된다.

## Goal

`todo export <output-file>` 명령을 구현한다. 기본 파일명은 `todos.csv`. 헤더 행과 데이터 행을 포함하는 RFC 4180 준수 CSV를 생성한다.

## In Scope

- `src/commands/export.ts` 신규 작성
- `src/index.ts`에 `export` 명령 등록
- CSV 직렬화 (외부 라이브러리 없이 순수 TypeScript)
- 기본 출력 파일명 `todos.csv`
- 성공/경고 메시지 콘솔 출력

## Out of Scope

- 날짜 필터링, 완료 여부 필터링
- JSON / Markdown 등 다른 내보내기 형식
- 기존 파일 덮어쓰기 확인 프롬프트 (공격적 설계 불필요)

## Functional Requirements

1. `todo export` — 현재 디렉터리에 `todos.csv` 생성
2. `todo export <path>` — 지정 경로에 CSV 생성
3. CSV 헤더 행: `id,title,completed,createdAt`
4. 필드 값에 쉼표/개행/큰따옴표가 포함된 경우 RFC 4180 규칙(큰따옴표 감싸기, `""` 이스케이프) 적용
5. todo가 없으면 헤더 행만 포함한 빈 CSV 생성 + 경고 메시지 출력
6. 저장 성공 시 `✔ Exported <N> todo(s) to <path>` 출력

## Constraints

- 외부 CSV 라이브러리 추가 금지 (번들 크기 유지)
- 기존 명령(add/list/done/delete/stats/clear)에 영향 없어야 함
- ESM, strict TypeScript 유지

## Acceptance

- [ ] `todo export` → `todos.csv` 생성, 헤더 + 데이터 행 확인
- [ ] `todo export out/report.csv` → 지정 경로 파일 생성
- [ ] title에 쉼표 포함 시 올바르게 이스케이프됨
- [ ] todo 없을 때 헤더만 있는 파일 생성 + 경고 메시지
- [ ] `npm run build` 통과
- [ ] `todo export --help` 도움말 출력

## Edge Cases and Error Handling

- 출력 디렉터리가 없을 경우: 명확한 에러 메시지 출력 후 비정상 종료
- 쓰기 권한 없을 경우: EACCES/EPERM 에러 메시지 출력
- title 필드에 큰따옴표 포함: `""` 이스케이프 적용

## Verification Baseline

```bash
npm run build
node dist/index.js export
cat todos.csv
node dist/index.js export test-output.csv
cat test-output.csv
node dist/index.js export --help
```

## Notes

- Source: rw-orchestrator/phase-0
- Created: 2026-02-22T00:00:00Z
- Assumptions: 사용자가 "전체 todo 목록" + "CSV 형식" 내보내기를 선택함
