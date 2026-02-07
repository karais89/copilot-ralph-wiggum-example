# Copilot Strict Simulation Prompt

```md
현재 워크스페이스의 Ralph Strict 워크플로우를 읽기 전용으로 시뮬레이션해줘. 파일 수정 금지.

기준 브랜치: `codex/rw-simulation-prompts`

대상 파일:
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-init.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-plan-strict.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-run-strict.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-archive.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.ai/GUIDE.md

시나리오:
1) rw-init -> rw-plan-strict -> rw-run-strict
2) completed/log 증가로 strict 내장 archive 발생
3) 동일 TASK 리뷰 3회 실패 (REVIEW_FAIL 1/3, 2/3, REVIEW-ESCALATE 3/3)
4) 중간 archive 발생 시 REVIEW_FAIL 카운팅 유지 여부
5) Strict 실행 중 외부 rw-archive 동시 실행 금지 규칙 검증

검증 포인트:
- REVIEW_FAIL 카운팅 범위가 PROGRESS + progress-archive/LOG-* 전체인지
- REVIEW-ESCALATE 감지 시 오케스트레이터 중단 여부
- 완료 판정 시 STATUS-*.md glob 전체 확인 여부
- TASK 유실/중복/무한루프 가능성

출력:
- Executive Summary: PASS/WARN/FAIL
- Scenario Result Table
- Findings(P1/P2/P3, 파일+라인)
- Final Verdict(즉시 사용 가능/조건부 가능/수정 필요)
```
