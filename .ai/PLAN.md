# Todo CLI 앱 — 제품 요구사항 문서

## 개요

Node.js와 TypeScript로 만든 커맨드라인 Todo 애플리케이션입니다.
사용자는 터미널에서 간단하고 직관적인 명령으로 할 일을 관리할 수 있습니다.

## Feature Notes (append-only)

- 2026-02-07: [todo-cli-baseline] 초기 베이스라인(추가/조회/완료/삭제, JSON 저장소, 에러 처리, 문서화) 적용. Related tasks: TASK-01~TASK-10.
- 2026-02-07: [stats-json-output] `todo stats` 명령과 선택적 `--json` 플래그 추가. 텍스트 출력은 total/completed/pending 통계를 표시하고, JSON 출력은 total/completed/pending/completionRate(0-100) 객체를 반환. Related tasks: TASK-11~TASK-13.

## 기술 스택

- **런타임**: Node.js (>=18)
- **언어**: TypeScript (strict mode)
- **CLI 프레임워크**: Commander.js
- **저장소**: 로컬 JSON 파일 (`data/todos.json`)
- **빌드**: `tsc` (TypeScript compiler)
- **패키지 매니저**: npm

## 데이터 모델

```typescript
interface Todo {
  id: string;          // nanoid 또는 UUID
  title: string;       // 할 일 설명
  completed: boolean;  // 완료 여부
  createdAt: string;   // ISO 8601 타임스탬프
}
```

## 기능 요구사항

### 명령어

| Command | Description | Example |
|---------|-------------|---------|
| `todo add <title>` | 새 todo 추가 | `todo add "Buy groceries"` |
| `todo list` | 전체 todo 조회 | `todo list` |
| `todo done <id>` | 특정 todo 완료 처리 | `todo done abc123` |
| `todo delete <id>` | 특정 todo 삭제 | `todo delete abc123` |

### 동작

- `add`: `completed: false`인 새 Todo를 생성하고 `id`와 `createdAt`을 자동 생성
- `list`: 포맷된 테이블로 모든 todo 출력. 완료는 `[✓]`, 미완료는 `[ ]` 표시
- `done`: 지정한 todo의 `completed` 값을 토글
- `delete`: 저장소에서 todo를 영구 삭제

## 비기능 요구사항

- 모든 명령어에서 안정적인 에러 처리(인자 누락, 잘못된 ID, 파일 오류)
- `todo --help`, `todo <command> --help` 도움말 제공
- 런타임 외부 의존성 최소화(Commander.js, nanoid 이외 없음)
- macOS, Linux, Windows에서 동작

## 프로젝트 구조

```
src/
├── index.ts          # CLI 진입점 (Commander 설정)
├── commands/
│   ├── add.ts        # add 명령 핸들러
│   ├── list.ts       # list 명령 핸들러
│   ├── update.ts     # done/update 명령 핸들러
│   └── delete.ts     # delete 명령 핸들러
├── models/
│   └── todo.ts       # Todo 인터페이스 및 타입 정의
└── storage/
    └── json-store.ts # JSON 파일 읽기/쓰기
```

## 코딩 규칙

- ESM 모듈 (`package.json`의 `"type": "module"`)
- Strict TypeScript (`"strict": true`)
- Conventional commit 사용 (예: `feat: add list command with table output`)
- 클래스보다 함수/모듈 중심
- 모든 함수에 명시적 반환 타입 작성
