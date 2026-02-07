# Copilot Strict Simulation Prompt

```md
현재 워크스페이스의 Ralph Strict 워크플로우를 읽기 전용으로 시뮬레이션해줘. 파일 수정 금지.

기준 브랜치: `main`

대상 파일:
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-init.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-plan-strict.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-run-strict.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-archive.prompt.md
- /Users/kaya/Documents/Github/context/context-github/.ai/GUIDE.md

시나리오:
1) rw-init -> rw-plan-strict -> rw-run-strict
2) completed/log 증가 시 rw-run-strict가 "수동 아카이브 필요"로 중단되는지
3) 동일 TASK 리뷰 3회 실패 (REVIEW_FAIL 1/3, 2/3, REVIEW-ESCALATE 3/3)
4) PAUSE.md 유지 후 rw-archive 수동 실행, 이후 strict 재개 시 REVIEW_FAIL 카운팅 유지 여부
5) Strict 실행 중 rw-archive 병행 금지 규칙 + PAUSE.md 선행 조건 검증

검증 포인트:
- REVIEW_FAIL 카운팅 범위가 활성 PROGRESS Log 전체인지
- REVIEW-ESCALATE 감지 시 오케스트레이터 중단 여부
- completed/log 임계치 초과 시 자동 archive 대신 중단 메시지 출력 여부
- 완료 판정 시 STATUS-*.md glob 전체 확인 여부
- TASK 유실/중복/무한루프 가능성

출력:
- Executive Summary: PASS/WARN/FAIL
- Scenario Result Table
- Findings(P1/P2/P3, 파일+라인)
- Final Verdict(즉시 사용 가능/조건부 가능/수정 필요)
```
