# .ai 폴더 — Ralph Wiggum 기법 프로젝트 관리

이 폴더는 Ralph Wiggum 기법을 사용하여 프로젝트를 자동으로 구현하기 위한 메타 파일들을 포함합니다.

## 📁 폴더 구조

```
.ai/
├── project/                    # 🔧 실제 프로젝트 작업 파일
│   ├── PLAN.md                 # 프로젝트 명세 (PRD)
│   ├── PROGRESS.md             # 진행 추적 (자동 업데이트)
│   └── tasks/                  # 개별 태스크 정의
│       ├── TASK-01-*.md
│       ├── TASK-02-*.md
│       └── ... (10개)
│
├── guides/                     # 📚 가이드 문서
│   ├── GUIDE-KO.md             # Ralph Wiggum 기법 완전 가이드 (한글)
│   └── GUIDE-EN.md             # Ralph Wiggum 기법 완전 가이드 (영어)
│
└── templates/                  # 📋 프롬프트 템플릿
    ├── ORCHESTRATOR-KO.md      # 오케스트레이터 프롬프트 (한글)
    ├── ORCHESTRATOR-EN.md      # 오케스트레이터 프롬프트 (영어)
    ├── SUBAGENT-KO.md          # 서브에이전트 프롬프트 (한글)
    └── SUBAGENT-EN.md          # 서브에이전트 프롬프트 (영어)
```

## 🎯 각 폴더의 역할

### 1. `project/` — 실제 작업 파일
- **PLAN.md**: 프로젝트 전체 명세 (Single Source of Truth)
- **PROGRESS.md**: 진행 상황 추적 (오케스트레이터 ↔ 서브에이전트 통신)
- **tasks/**: 개별 태스크 정의 (의존성, 완료 기준 포함)

**이 폴더의 파일들은 실행 중 자주 업데이트됩니다.**

### 2. `guides/` — 참고 문서
- **GUIDE-KO.md**: 한글 완전 가이드 (9개 섹션, 500줄)
  - 소개, 개념, 프로젝트 구조, 파일 포맷, 사용 방법, 프롬프트 엔지니어링, 비용 절약, 모범 사례, 문제 해결
- **GUIDE-EN.md**: 영어 완전 가이드

**이 가이드들을 먼저 읽으세요!**

### 3. `templates/` — 프롬프트 템플릿
- **ORCHESTRATOR-KO.md** / **ORCHESTRATOR-EN.md**: 
  - VS Code Copilot Chat에 복사-붙여넣기하여 오케스트레이션 루프 시작
- **SUBAGENT-KO.md** / **SUBAGENT-EN.md**: 
  - 서브에이전트의 작업 프로세스 정의
  - 오케스트레이터 프롬프트에 이미 포함되어 있습니다

**이 파일들은 정적입니다 (프로젝트 어느 프로젝트에서도 재사용 가능).**

---

## 🚀 빠른 시작

### 1단계: 가이드 읽기
```bash
# 한글
.ai/guides/GUIDE-KO.md

# 영어
.ai/guides/GUIDE-EN.md
```

### 2단계: 오케스트레이터 프롬프트 복사
```bash
# 원하는 언어의 템플릿 복사:
.ai/templates/ORCHESTRATOR-KO.md   (한글)
.ai/templates/ORCHESTRATOR-EN.md   (영어)
```

### 3단계: VS Code Copilot Chat에 붙여넣기
1. Copilot Chat 열기 (Opus 모델 선택)
2. 프롬프트 파일 내용 복사
3. Chat에 붙여넣기
4. Enter → 자동 실행!

---

## 📌 중요 사항

### 수정 금지 (Static)
- `guides/GUIDE-*.md` — 참고용, 프로젝트별로 다를 수 있음
- `templates/ORCHESTRATOR-*.md` — 다른 프로젝트에도 재사용 가능
- `templates/SUBAGENT-*.md` — 서브에이전트 역할 정의

### 수정 필수 (Dynamic)
- `project/PLAN.md` — 프로젝트별로 다름
- `project/tasks/*.md` — 매 태스크 작성 시마다 생성
- `project/PROGRESS.md` — 실행 중 자동 업데이트

---

## 🔄 파일 흐름

```
templates/ORCHESTRATOR-KO.md (복사)
        ↓
VS Code Copilot Chat
        ↓
Orchestrator Agent
        ↓
runSubagent 호출 (templates/SUBAGENT-KO.md 전달)
        ↓
Subagent Agent
        ↓
1. project/PLAN.md 읽기
2. project/PROGRESS.md 읽기
3. project/tasks/*.md 읽기
4. 태스크 구현
5. project/PROGRESS.md 업데이트
6. Git 커밋
        ↓
Orchestrator: project/PROGRESS.md 다시 읽기
        ↓
모든 태스크 완료? → YES → 종료 / NO → 반복
```

---

## 💡 팁

### 한글과 영어 템플릿 선택
- **한글**: `.ai/templates/ORCHESTRATOR-KO.md` 복사
- **영어**: `.ai/templates/ORCHESTRATOR-EN.md` 복사

### 에러 발생 시
1. `guides/GUIDE-KO.md` 또는 `GUIDE-EN.md`의 "문제 해결" 섹션 참고
2. `project/PROGRESS.md`에서 마지막 완료 태스크 확인
3. 다음 태스크의 의존성 확인

### 다른 프로젝트에서 재사용
1. `templates/` 폴더 전체 복사
2. `project/` 폴더만 새로 생성
3. `PLAN.md`, `tasks/*.md` 새로 작성
4. 오케스트레이터 시작

---

## 🎓 학습 자료

### 최소한 읽어야 할 부분
- `guides/GUIDE-KO.md` → "소개", "핵심 개념", "사용 방법"

### 깊이 있게 학습하려면
- `guides/GUIDE-KO.md` 전체 (30~40분)
- `templates/ORCHESTRATOR-KO.md` 읽기 (이해)

### 트러블슈팅
- `guides/GUIDE-KO.md` → "문제 해결" 섹션

---

## 📞 문의

각 파일의 내용이 명확하지 않으면:
1. `guides/`의 해당 섹션 참고
2. `templates/` 파일의 주석 읽기
3. `project/tasks/` 파일에서 실제 사례 확인

---

**Happy Orchestrating! 🎭**
