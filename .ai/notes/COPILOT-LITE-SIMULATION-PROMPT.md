# Copilot Lite Simulation Prompt

```md
현재 워크스페이스의 Ralph Lite 워크플로우를 읽기 전용으로 시뮬레이션해줘. 파일 수정 금지.

기준 브랜치: `main`

대상 파일:
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-init.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-plan-lite.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-run-lite.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-archive.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.ai/GUIDE.md

시나리오:
1) rw-init 실행 가정
2) rw-plan-lite로 기능 1개 추가 가정
3) rw-run-lite로 TASK 완료 루프 가정
4) completed > 20 또는 PROGRESS > 8000 chars 임계치 도달 시 경고 출력 후 계속 진행되는지 확인
5) TASK 50+ 장기 운영 후 rw-archive 수동 실행 가정

검증 포인트:
- TASK 번호 중복/유실 없는지
- PROGRESS 상태 전이(pending -> completed) 일관성
- Lite 임계치 도달 시 자동 중단/자동 archive 없이 경고만 출력되는지
- rw-archive 실행 타이밍(반드시 rw-run-lite 정지 상태) 충돌 여부
- rw-archive 이후에도 Task ID 유실 없이 루프 재개 가능한지

출력:
- Executive Summary: PASS/WARN/FAIL
- 단계별 상태 스냅샷(PLAN/PROGRESS/tasks/archive)
- Findings(P1/P2/P3, 파일+라인)
- Final Verdict
```
