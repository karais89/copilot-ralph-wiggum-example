# 프롬프트 템플릿

VS Code Copilot Chat에서 오케스트레이션 루프를 시작하기 위한 템플릿입니다.

## 📋 템플릿 목록

### 오케스트레이터 프롬프트
오케스트레이션 루프를 시작할 때 **이 파일을 복사해서 Copilot Chat에 붙여넣습니다.**

- **[ORCHESTRATOR-KO.md](./ORCHESTRATOR-KO.md)** ← **여기서 시작!** (한글)
- **[ORCHESTRATOR-EN.md](./ORCHESTRATOR-EN.md)** (영어)

### 서브에이전트 프롬프트
오케스트레이터가 `runSubagent` 호출 시 전달하는 프롬프트입니다.
*(일반적으로 직접 사용할 필요 없음. 오케스트레이터에 이미 포함됨)*

- **[SUBAGENT-KO.md](./SUBAGENT-KO.md)** (한글)
- **[SUBAGENT-EN.md](./SUBAGENT-EN.md)** (영어)

---

## 🚀 빠른 시작

### 1단계: 템플릿 선택
```bash
# 한글 프로젝트
templates/ORCHESTRATOR-KO.md 복사

# 영어 프로젝트
templates/ORCHESTRATOR-EN.md 복사
```

### 2단계: 내용 복사
```bash
전체 파일 내용 복사 (Cmd+A → Cmd+C)
```

### 3단계: Copilot Chat에 붙여넣기
```
1. VS Code 열기
2. Copilot Chat 열기 (#8 icon)
3. "New Chat" 클릭
4. Opus 모델 선택 (권장)
5. 프롬프트 복사본 붙여넣기
6. Enter 키 → 자동 실행!
```

---

## 📁 파일 구조

```
templates/
├── ORCHESTRATOR-KO.md      # ← 한글 추천
├── ORCHESTRATOR-EN.md
├── SUBAGENT-KO.md          # 참고용 (일반적으로 직접 사용 안 함)
├── SUBAGENT-EN.md
└── README.md               # 이 파일
```

---

## 🎯 각 파일의 역할

### ORCHESTRATOR-KO.md / ORCHESTRATOR-EN.md
**목적**: 오케스트레이션 루프 시작

**구성**:
1. 파일 경로 지정 (`<PLAN>`, `<TASKS>`, `<PROGRESS>`)
2. 오케스트레이터 역할과 책임
3. 구현 루프 로직
4. 서브에이전트 프롬프트 (내장)

**사용 시기**:
- 프로젝트 시작할 때
- 모든 태스크가 대기 중일 때
- 오케스트레이션 재시작이 필요할 때

**사용 방법**:
1. 이 파일의 전체 내용 복사
2. VS Code Copilot Chat에 붙여넣기
3. 자동 실행

### SUBAGENT-KO.md / SUBAGENT-EN.md
**목적**: 서브에이전트의 작업 프로세스 정의

**구성**:
1. 서브에이전트 역할
2. 태스크 선택 전략
3. 구현 단계별 가이드
4. DO/DON'T 규칙
5. 품질 기준
6. 예제 워크플로우

**사용 시기**:
- 일반적으로 직접 사용하지 않음
- 오케스트레이터가 `runSubagent` 호출 시 자동으로 전달됨
- 서브에이전트 역할을 이해하고 싶을 때 참고

**배경 정보**:
- ORCHESTRATOR 프롬프트 안에 내장되어 있음
- 오케스트레이터가 runSubagent 호출 시 이 프롬프트를 전달

---

## 💡 팁

### 한글 vs 영어 선택
- **한글**: 프로젝트가 한국어 중심이면 ORCHESTRATOR-KO.md 사용
- **영어**: 국제 프로젝트거나 영어 선호하면 ORCHESTRATOR-EN.md 사용
- **혼합**: 가능하지만 한 프로젝트에는 하나의 언어로 통일 권장

### 프롬프트 커스터마이징
필요시 템플릿을 복사한 후 수정:
```markdown
# 예: 프로젝트 경로 변경
<PLAN>.ai/project/PLAN.md</PLAN>
<TASKS>.ai/project/tasks/</TASKS>
<PROGRESS>.ai/project/PROGRESS.md</PROGRESS>

# 또는 다른 경로로 변경 가능
<PLAN>docs/PLAN.md</PLAN>
```

### 실패한 오케스트레이션 재시작
1. `PROGRESS.md` 확인하여 마지막 완료 태스크 확인
2. 동일한 ORCHESTRATOR 프롬프트 다시 사용
3. 오케스트레이터가 마지막 완료 행부터 계속 진행

---

## 🔄 오케스트레이션 흐름

```
ORCHESTRATOR-KO.md 템플릿
    ↓ (복사 & 붙여넣기)
VS Code Copilot Chat
    ↓
Orchestrator Agent 시작
    ↓
project/PROGRESS.md 읽기
    ↓
미완료 태스크 있나?
    ├─ YES: runSubagent 호출 + SUBAGENT 프롬프트 전달
    │         ↓
    │       Subagent 실행 & 태스크 구현
    │         ↓
    │       PROGRESS.md 업데이트 & Git 커밋
    │         ↓
    │       Orchestrator: PROGRESS.md 다시 읽기
    │
    └─ NO: ✅ 종료 & 성공 메시지
```

---

## 📌 중요 사항

### 필수 읽기
- 가이드: `../guides/GUIDE-KO.md` 또는 `GUIDE-EN.md` (먼저 읽기!)
- 영역: "사용 방법" 섹션

### 편집 금지
- 이 템플릿 파일들은 어떤 프로젝트에서든 재사용 가능합니다
- 프로젝트별로 다른 부분은 `../project/` 폴더의 파일들입니다

### 프로젝트별로 수정 필요
- `../project/PLAN.md` (프로젝트 명세)
- `../project/tasks/TASK-XX-*.md` (개별 태스크)
- `../project/PROGRESS.md` (진행 추적, 자동 생성)

---

## ✅ 使用 前 체크리스트

- [ ] `../guides/GUIDE-KO.md` 또는 `GUIDE-EN.md` 읽기 (필수)
- [ ] 프로젝트의 `../project/PLAN.md` 작성 완료
- [ ] 모든 `../project/tasks/TASK-XX-*.md` 작성 완료
- [ ] 적합한 언어 버전 선택 (KO 또는 EN)
- [ ] ORCHESTRATOR 프롬프트 준비 완료
- [ ] VS Code Copilot Chat 실행 준비

---

## 🆘 문제 해결

**Q: 어떤 템플릿을 선택해야 하나요?**
A: 한글 프로젝트면 ORCHESTRATOR-KO.md, 영어면 ORCHESTRATOR-EN.md

**Q: SUBAGENT 프롬프트는 언제 사용하나요?**
A: 일반적으로 직접 사용하지 않습니다. ORCHESTRATOR에 내장되어 있고, 오케스트레이터가 자동으로 전달합니다.

**Q: 프롬프트를 수정해도 되나요?**
A: 네, 프로젝트 경로 등을 커스터마이징할 수 있습니다. 하지만 먼저 가이드를 읽고 이해한 후 수정하세요.

**Q: 다른 프로젝트에서 이 템플릿을 재사용할 수 있나요?**
A: 네! 이 템플릿들은 프로젝트에 독립적이므로 어디서든 재사용 가능합니다.

---

## 📞 참고 자료

- **가이드**: `../guides/GUIDE-KO.md` 또는 `GUIDE-EN.md`
- **프로젝트 파일**: `../project/PLAN.md`, `../project/tasks/`, `../project/PROGRESS.md`
- **전체 네비게이션**: `../.ai/README.md`

---

**이제 [ORCHESTRATOR-KO.md](./ORCHESTRATOR-KO.md) 또는 [ORCHESTRATOR-EN.md](./ORCHESTRATOR-EN.md)를 복사해서 시작하세요!** 🚀
