# 개선 계획: .ai 폴더 구조 간소화 및 원글 반영

## 목표

원글(Reddit Ralph Wiggum 기법)의 핵심 철학 — **"간결하게, 바로 작동하게"** — 에 맞추면서 현재 프로젝트의 좋은 점을 유지한다.

---

## 현재 구조 → 목표 구조

### Before (16개 파일, 3단계 중첩)

```
.ai/
├── README.md
├── project/
│   ├── README.md
│   ├── PLAN.md
│   ├── PROGRESS.md
│   └── tasks/ (10개)
├── guides/
│   ├── README.md
│   ├── GUIDE-KO.md
│   └── GUIDE-EN.md
└── templates/
    ├── README.md
    ├── ORCHESTRATOR-KO.md
    ├── ORCHESTRATOR-EN.md
    ├── SUBAGENT-KO.md
    └── SUBAGENT-EN.md
```

### After (플랫 구조)

```
.ai/
├── PLAN.md                    # PRD (유지)
├── PROGRESS.md                # 진행 추적 (유지, 자동생성)
├── ORCHESTRATOR.md            # 오케스트레이터 프롬프트 (1개로 통합, 서브에이전트 인라인)
├── tasks/                     # 태스크 파일 (유지)
│   ├── TASK-01-*.md
│   └── ...
└── GUIDE.md                   # 가이드 (1개로 통합, 선택적)
```

---

## 변경 항목

### 1. 폴더 구조 플랫화

- `project/`, `guides/`, `templates/` 3단계 중첩 제거
- PLAN.md, PROGRESS.md, tasks/ → `.ai/` 루트로 이동
- 폴더별 README 4개 전부 제거 (.ai/README.md, project/README.md, guides/README.md, templates/README.md)

### 2. 이중 언어 → 단일 언어

- ORCHESTRATOR-KO.md + ORCHESTRATOR-EN.md → **ORCHESTRATOR.md** 1개 (한글)
- SUBAGENT-KO.md + SUBAGENT-EN.md → 삭제 (ORCHESTRATOR.md에 인라인)
- GUIDE-KO.md + GUIDE-EN.md → **GUIDE.md** 1개 (한글)

### 3. 오케스트레이터 프롬프트 개선

현재 ~130줄 → **~50줄** 목표. 원글 수준의 간결함 유지.

추가 반영:
- **PAUSE 체크 로직**: 각 루프 시작 시 `.ai/PAUSE.md` 존재 확인
- **Task Reviewer 서브에이전트**: 원글 최신 업데이트 반영 — 각 태스크 완료 후 리뷰어 서브에이전트 호출하여 구현 검증

### 4. 서브에이전트 프롬프트 대폭 축소

현재 ~200줄 → **~30줄** 목표. 원글처럼 핵심만:
- 컨텍스트 파일 경로
- 미완료 태스크 중 가장 중요한 것 선택
- 구현 + 빌드 검증
- PROGRESS.md 업데이트
- Conventional commit
- 종료

제거 대상:
- 7단계 프로세스 상세 설명
- 태스크 선택 전략 (우선순위 1~4)
- 에러 처리 가이드
- 품질 기준
- 워크플로우 예시
- 로그 항목 예시

### 5. 가이드 축소

현재 ~500줄 × 2언어 → **~150줄** 1개 목표:
- 소개 (왜 쓰나)
- 빠른 시작 (3단계)
- 파일 포맷 (PLAN, TASK, PROGRESS 최소 스펙)
- 문제 해결 (핵심 5개만)

---

## 태스크 목록

| # | 태스크 | 설명 |
|---|--------|------|
| 1 | ORCHESTRATOR.md 재작성 | 간결한 오케스트레이터 프롬프트 (~50줄) + 서브에이전트 인라인 (~30줄) + PAUSE 체크 + Task Reviewer |
| 2 | GUIDE.md 재작성 | 압축된 단일 가이드 (~150줄, 한글) |
| 3 | 파일 이동 | PLAN.md, PROGRESS.md, tasks/ → .ai/ 루트로 이동 |
| 4 | 불필요 파일 삭제 | README 4개, 이중 언어 템플릿 4개, 독립 SUBAGENT 2개 삭제 |
| 5 | 루트 README.md 업데이트 | 새 구조 반영 |

---

## 참고: 원글 핵심 프롬프트 (비교용)

### 원글 오케스트레이터 (~20줄)

```
You are an orchestration agent. You will trigger subagents that will execute
the complete implementation of a plan and series of tasks, and carefully follow
the implementation of the software until full completion. Your goal is NOT to
perform the implementation but verify the subagents does it correctly.

The master plan is in <PLAN>, and the series of tasks are in <TASKS>.

You will communicate with subagent mainly through a progress file <PROGRESS>.
First you need to create the progress file if it does not exist.

Then you will start the implementation loop and iterate until all tasks are finished.

You HAVE to start a subagent with <SUBAGENT_PROMPT>. The subagent is responsible
to list all remaining tasks and pick the one that it thinks is the most important.

You have to have access to the runSubagent tool. If you do not have this tool
available fail immediately. You will call each time the subagent sequentially,
until ALL tasks are declared as completed in the progress file.

Each iteration shall target a single feature and will perform autonomously all
the coding, testing, and commit. You are responsible to see if each task has been
completely completed.

You focus only on this loop trigger/evaluation.
```

### 원글 서브에이전트 (~15줄)

```
You are a senior software engineer coding agent working on developing the PRD
specified in <PLAN>. The main progress file is in <PROGRESS>. The list of tasks
to implement is in <TASKS>.

You need to pick the unimplemented task you think is the most important.
This is not necessarily the first one.

Think thoroughly and perform the coding of the selected task, and this task only.
You have to complete its implementation.

When you have finished the implementation of the task, you have to ensure the
preflight campaign `just preflight` pass, and fix all potential issues until
the implementation is complete.

Update progress file once your task is completed.

Then commit the change using a direct, concise, conventional commit.
Focus on the impact on the user.

Once you have finished the implementation of your task and commit, leave.
```

---

## 판단 기준

- 오케스트레이터 프롬프트를 복사-붙여넣기하면 **바로 작동**해야 함
- 서브에이전트 프롬프트는 **신선한 컨텍스트에서도 충분히 이해 가능**해야 함
- 문서를 읽지 않아도 사용할 수 있어야 함 (가이드는 선택적)
- 파일 수 최소화 (현재 16개 → 목표 ~5개 + tasks/)
