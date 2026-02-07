# 진행 현황

## Task Status

| Task | Title | Status | Commit |
|------|-------|--------|--------|
| TASK-01 | 프로젝트 초기화 | completed | feat: init project |
| TASK-02 | 데이터 모델 정의 | completed | feat: define Todo model |
| TASK-03 | 저장소 레이어 | completed | feat: implement storage layer |
| TASK-04 | Add 명령어 | completed | feat: implement add command |
| TASK-05 | List 명령어 | completed | feat: implement list command |
| TASK-06 | Update (Done) 명령어 | completed | feat: implement done command |
| TASK-07 | Delete 명령어 | completed | feat: implement delete command |
| TASK-08 | CLI 엔트리포인트 | completed | feat: wire up CLI with Commander.js |
| TASK-09 | 에러 처리 | completed | feat: add comprehensive error handling |
| TASK-10 | README 문서화 | completed | docs: write README |
| TASK-11 | Stats 명령 핸들러 | completed | feat: add stats command with text and JSON output |
| TASK-12 | Stats 명령 CLI 연결 | completed | feat: register stats command in CLI |
| TASK-13 | Stats 통합 테스트 | completed | test: verify stats command integration |
| TASK-14 | Add stats --json flag | completed | feat(stats): add -j/--json flag to stats command |
| TASK-15 | Define stats JSON schema | pending | - |
| TASK-16 | Add tests for stats JSON | pending | - |
| TASK-17 | Docs/examples and integration check | pending | - |

## Log

- **2026-02-06** — TASK-01 completed: package.json(ESM), tsconfig.json(strict), .gitignore를 포함해 프로젝트를 초기화하고 commander/nanoid 및 개발 의존성을 설치했습니다. `src/` 기본 구조를 생성했으며 빌드 통과.
- **2026-02-06** — TASK-02 completed: `src/models/todo.ts`에 Todo 인터페이스(id, title, completed, createdAt)와 `createTodo()` 헬퍼를 정의했습니다. 빌드 통과.
- **2026-02-06** — TASK-03 completed: `loadTodos()`, `saveTodos()` 기반 JSON 저장소 레이어를 구현했습니다. `data/` 디렉터리와 `todos.json` 자동 생성, 파일 누락/파싱 오류 처리 포함. 빌드 통과.
- **2026-02-06** — TASK-04 completed: add 명령 핸들러를 구현했습니다. 입력 검증, 기존 todo 로드, 저장소 반영, 사용자 확인 메시지를 포함합니다. 빌드 통과.
- **2026-02-06** — TASK-05 completed: list 명령 핸들러를 구현했습니다. 완료 `[✓]`, 미완료 `[ ]`, 축약 ID(앞 8자리), 제목을 포맷 출력하며 비어 있을 때 안내 메시지와 총 개수를 표시합니다. 빌드 통과.
- **2026-02-06** — TASK-06 completed: done 명령 핸들러를 구현했습니다. 전체 ID/접두어 매칭으로 todo를 찾아 완료 상태를 토글하고 저장합니다. 미매칭 시 오류를 반환합니다. 빌드 통과.
- **2026-02-06** — TASK-07 completed: delete 명령 핸들러를 구현했습니다. 전체 ID/접두어 매칭으로 todo를 영구 삭제하고 삭제된 항목 제목을 출력합니다. 미매칭 시 오류를 반환합니다. 빌드 통과.
- **2026-02-06** — TASK-08 completed: Commander.js 기반 CLI 엔트리포인트를 구성했습니다. 프로그램명(`todo`), 버전(`1.0.0`), 설명, add/list/done/delete 명령 등록 및 오류 처리를 연결했습니다. 빌드 통과.
- **2026-02-06** — TASK-09 completed: 전역 예외/거부 처리와 명령별 try/catch를 추가해 에러 처리를 강화했습니다. 저장소 계층에서 권한(EACCES/EPERM), 디스크 가득 참(ENOSPC), 읽기 전용(EROFS) 오류를 구분 처리합니다. 빌드 통과.
- **2026-02-06** — TASK-10 completed: README 문서를 작성했습니다. 설치, 명령 사용 예시(add/list/done/delete), 출력 예시, 기술 스택, 프로젝트 구조, 저장소, 개발 스크립트, 라이선스를 포함합니다. 빌드 통과.
- **2026-02-07** — [stats-json-output] 기능 계획 태스크 TASK-11~TASK-13 추가.
- **2026-02-07** — TASK-11 completed: `src/commands/stats.ts`에 stats 명령 핸들러를 구현했습니다. total/completed/pending/completionRate(0-100)를 계산하며 기본 텍스트 출력과 `--json` 출력 모두 지원합니다. 빌드 통과.
- **2026-02-07** — TASK-12 completed: `src/index.ts`에 stats 명령을 등록했습니다. `--json` 옵션 전달, 일관된 오류 처리, `todo --help`/`todo stats --help` 출력 확인을 완료했습니다. 빌드 통과.
- **2026-02-07** — TASK-13 completed: stats 명령 통합 검증을 수행했습니다. 빈 상태(0개), 혼합 상태(2개 중 1개 완료), 텍스트/JSON 출력, `jq` 파싱, 도움말 노출을 확인했고 모든 완료 기준을 충족했습니다. 빌드 통과.
- **2026-02-07** — Added feature planning tasks TASK-14~TASK-17 for [add-stats-command-json-output-mode].
- **2026-02-07** — TASK-15 completed: Defined minimal JSON schema for `stats --json` and implemented schema fields (`total`, `completed`, `pending`, `overdue`, `generated_at`) in `src/commands/stats.ts`. CLI now emits structured JSON errors when `--json` is requested. Build passed.
 - **2026-02-07** — TASK-15 completed: Defined minimal JSON schema for `stats --json` and implemented schema fields (`total`, `completed`, `pending`, `overdue`, `generated_at`) in `src/commands/stats.ts`. CLI now emits structured JSON errors when `--json` is requested. Build passed.
 - **2026-02-07** — REVIEW_FAIL TASK-15 (1/3): Missing README example and missing unit tests verifying JSON keys/types; reverting TASK-15 to `pending` for follow-up.
 - **2026-02-07** — TASK-14 completed: Added `-j, --json` short alias for the `stats` command in `src/index.ts`. Verified build and manual run: `node dist/index.js stats -j` prints JSON when built. Commit: `feat(stats): add -j/--json flag to stats command`.
