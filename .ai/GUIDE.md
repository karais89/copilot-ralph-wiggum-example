```markdown
# Ralph Wiggum 기법 가이드

VS Code Copilot Chat의 `runSubagent`를 활용하여 프로젝트를 자율적으로 구현하는 오케스트레이션 패턴입니다.

---

## 왜 쓰나?

- **비용 절약**: 오케스트레이터 1회 = 1 프리미엄 요청, `runSubagent` 호출은 추가 과금 없음
- **컨텍스트 분리**: 각 서브에이전트가 독립 실행 → "message too big" 방지
- **추적 가능성**: 모든 진행 상황이 `PROGRESS.md`에 기록됨

---

## 빠른 시작

### 1단계: .ai/ 폴더 준비

```
.ai/
├── PLAN.md              # PRD — 프로젝트 전체 명세
├── ORCHESTRATOR.md      # 오케스트레이터 프롬프트 (서브에이전트 포함)
├── tasks/               # 개별 태스크 파일
│   ├── TASK-01-주제.md
│   └── ...
└── GUIDE.md             # 이 가이드 (선택적)
```

- `PLAN.md`: Claude에게 "이 아이디어의 PRD를 작성해줘"로 초안 생성
- `tasks/`: "PLAN.md를 10~20개 태스크로 분할해줘"로 생성
- `PROGRESS.md`: 오케스트레이터가 자동 생성

### 2단계: 오케스트레이터 실행

1. VS Code Copilot Chat → New Chat (Opus 권장)
2. `ORCHESTRATOR.md` 내용 복사-붙여넣기
3. 엔터 → 자동 루프 시작

### 3단계: 모니터링

- `PROGRESS.md` 실시간 확인
- `git log --oneline`으로 커밋 추적
- 개입 필요 시 `.ai/PAUSE.md` 생성 → 오케스트레이터 일시 정지

---

## 파일 포맷

### PLAN.md

```markdown
# 프로젝트명 — Product Requirements Document

## Overview
프로젝트 개요

## Tech Stack
- Runtime / Language / Framework

## Data Model
핵심 데이터 구조 (코드 블록)

## Functional Requirements
기능 목록 (커맨드, API 등)

## Non-Functional Requirements
에러 처리, 성능, 보안

## Project Structure
폴더/파일 구조

## Coding Conventions
모듈 시스템, 타입, 커밋 규칙
```

### tasks/TASK-XX-주제.md

```markdown
# TASK-XX: 제목

## Status: pending
## Dependencies: [TASK-YY]

## Description
구현할 내용

## Acceptance Criteria
- [ ] 기준 1
- [ ] 기준 2

## Files to Create/Modify
- src/파일.ts
```

**태스크 분할 원칙**: 각 태스크는 30분~2시간 크기, 명확한 의존성, 순환 참조 없음.

### PROGRESS.md (자동 생성)

```markdown
# Progress

## Task Status
| Task | Title | Status | Commit |
|------|-------|--------|--------|
| TASK-01 | 주제 | pending | - |

## Log
- **YYYY-MM-DD** — TASK-XX completed: 설명
```

---

## 문제 해결

| 문제 | 해결 |
|------|------|
| 서브에이전트가 잘못된 태스크 선택 | PROGRESS.md 수동 수정 후 재시작 |
| Rate limit 에러 | 대기 후 재시도, 또는 PAUSE.md 생성 |
| 특정 태스크 반복 실패 | 태스크를 더 작게 분할하여 재작성 |
| PROGRESS.md 업데이트 누락 | 수동 수정 후 다음 루프에서 자동 복구 |
| 컨텍스트 오버플로우 | PLAN.md 축약, 태스크 분할 |

---

## 참고

- [Conventional Commits](https://www.conventionalcommits.org/)
- [VS Code Copilot Docs](https://code.visualstudio.com/docs/copilot)
```
