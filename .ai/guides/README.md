# 가이드 문서

Ralph Wiggum 기법을 사용하여 프로젝트를 자동으로 구현하는 방법에 대한 완전한 가이드입니다.

## 📚 문서 목록

### 한글
- **[GUIDE-KO.md](./GUIDE-KO.md)** (권장)
  - Ralph Wiggum 기법 완전 가이드
  - 9개 섹션: 소개 → 개념 → 구조 → 포맷 → 사용법 → 프롬프트 → 비용 → 사례 → 해결
  - 약 500줄, 30~40분 소요

### 영어
- **[GUIDE-EN.md](./GUIDE-EN.md)**
  - Complete Ralph Wiggum Technique Guide
  - 9 sections: Introduction → Concepts → Structure → Formats → Usage → Prompts → Cost → Best Practices → Troubleshooting
  - ~500 lines, 30-40 minutes

---

## 🚀 빠른 네비게이션

### 지금 바로 알고 싶다면
1. 가이드의 "소개" 섹션 읽기 (2분)
2. 가이드의 "사용 방법" 섹션 읽기 (10분)
3. `../templates/ORCHESTRATOR-KO.md` 복사 & 실행

### 자세히 이해하려면
1. 가이드 전체 읽기 (40분)
2. 실제 `../project/` 파일들 확인
3. 오케스트레이터 프롬프트 실행

### 문제가 생겼다면
1. 가이드의 "문제 해결" 섹션 (A-5 참고)
2. 가이드의 "모범 사례" 섹션 재확인
3. `../project/PROGRESS.md` 상태 확인

---

## 📖 가이드 구조

모든 가이드는 다음 9개 섹션을 포함합니다:

| # | 섹션 | 목적 | 시간 |
|---|------|------|------|
| 1 | 소개 | Ralph Wiggum 기법이 뭔지 | 2분 |
| 2 | 핵심 개념 | 3요소 시스템 (PLAN, TASKS, PROGRESS) | 3분 |
| 3 | 프로젝트 구조 | `.ai/` 폴더 및 파일 배치 | 3분 |
| 4 | 파일 포맷 | PLAN.md, TASK-XX.md, PROGRESS.md 작성법 | 5분 |
| 5 | 사용 방법 | 단계별 실행 가이드 | 8분 |
| 6 | 프롬프트 엔지니어링 | 오케스트레이터/서브에이전트 프롬프트 최적화 | 5분 |
| 7 | 비용 절약 효과 | 기존 vs Ralph Wiggum 비교 | 3분 |
| 8 | 모범 사례 | DO/DON'T 및 체크리스트 | 5분 |
| 9 | 문제 해결 | Q&A 형식 트러블슈팅 | 5분 |

---

## 💡 권장 학습 경로

### 1단계: 가볍게 시작 (15분)
- [ ] 가이드 "소개" 읽기
- [ ] 가이드 "핵심 개념" 읽기
- [ ] 이 문서 (README) 읽기

### 2단계: 준비 (20분)
- [ ] 가이드 "프로젝트 구조" 읽기
- [ ] 가이드 "파일 포맷" 읽기
- [ ] `../project/PLAN.md` 예제 확인

### 3단계: 실행 준비 (10분)
- [ ] 가이드 "사용 방법" 읽기
- [ ] `../templates/ORCHESTRATOR-KO.md` 확인
- [ ] `../templates/SUBAGENT-KO.md` 확인

### 4단계: 실행
- [ ] `../templates/ORCHESTRATOR-KO.md` 복사
- [ ] VS Code Copilot Chat에 붙여넣기
- [ ] 자동 실행!

### 5단계: 트러블슈팅 (필요 시)
- [ ] 가이드 "문제 해결" 읽기
- [ ] `../project/PROGRESS.md` 상태 확인

---

## 🎯 각 문서의 역할

### GUIDE-KO.md (한글)
```
When to read: 한국어를 선호할 때
Best for: 깊이 있는 학습
Contains: 9개 섹션, 체크리스트, 고급 기능 설명
```

### GUIDE-EN.md (영어)
```
When to read: English preferred
Best for: English speakers
Contains: 9 sections, checklists, advanced features
```

---

## 🔗 관련 파일

- **템플릿 보기**: `../templates/` 폴더
  - `ORCHESTRATOR-KO.md` ← 여기서 시작!
  - `ORCHESTRATOR-EN.md`
  - `SUBAGENT-KO.md`
  - `SUBAGENT-EN.md`

- **프로젝트 파일**: `../project/` 폴더
  - `PLAN.md` (프로젝트 명세)
  - `PROGRESS.md` (진행 추적)
  - `tasks/` (개별 태스크)

---

## 📌 핵심 포인트

1. **프롬프트 템플릿은 정적**: 어떤 프로젝트에서든 재사용 가능
2. **프로젝트 파일은 동적**: 프로젝트별로 다름
3. **먼저 읽어야 함**: GUIDE-KO.md의 "사용 방법" 섹션
4. **그 다음 복사**: `templates/ORCHESTRATOR-KO.md`
5. **마지막 실행**: VS Code Copilot Chat

---

## ✅ 시작하기 전 체크리스트

- [ ] GUIDE-KO.md의 "소개"와 "핵심 개념" 읽기
- [ ] 가이드의 "사용 방법" 섹션 이해
- [ ] 프로젝트의 PLAN.md 작성 완료
- [ ] 모든 TASK-XX-*.md 파일 작성 완료
- [ ] `templates/ORCHESTRATOR-KO.md` 준비 완료
- [ ] VS Code Copilot Chat 오픈 준비

---

**이제 GUIDE-KO.md를 읽고 시작하세요! 🚀**
