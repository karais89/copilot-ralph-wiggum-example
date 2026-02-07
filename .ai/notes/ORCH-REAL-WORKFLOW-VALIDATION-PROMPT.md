# 메인 오케스트라 실행 기반 검증 프롬프트 (재사용용)

아래 지시를 그대로 수행하라.

## 목표
- 시뮬레이션/추정 없이, 메인 오케스트라(Lite + Strict)가 실제 실행에서 정상 동작하는지 검증한다.

## 대상 프롬프트
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-feature.prompt.md`
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-plan-lite.prompt.md`
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-run-lite.prompt.md`
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-plan-strict.prompt.md`
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-run-strict.prompt.md`
- `/Users/kaya/Documents/Github/context/context-github/.github/prompts/rw-archive.prompt.md`

## 절대 규칙
1. 시뮬레이션 금지. 실제 명령 실행 결과만 사용.
2. 각 단계마다 반드시 기록:
   - 실행 명령
   - exit code
   - 핵심 출력 1~3줄
   - 변경 파일 목록
3. 실행 증거 누락 시 해당 단계는 FAIL.
4. 실패 시 원인 수정 후 해당 단계부터 재실행.
5. 증거 보존 전까지 `git checkout -- <file>`, `git restore`, 브랜치 삭제 금지.
6. 최종 보고서에 검증 시점의 `branch`와 `HEAD commit`을 반드시 기록.

## 검증 명령 선택 규칙 (언어 비종속)
1. 프로젝트의 표준 검증 명령을 먼저 결정한다:
   - build/compile 1개
   - test 1개
   - runtime smoke 1개(앱/패키지 엔트리 실행 가능성 확인)
2. 명령이 문서/스크립트에 여러 개면 가장 표준적인 것 1개씩 선택하고 이유를 기록한다.

## 실행 시나리오
1. Lite 정상 흐름:
   - feature 생성 -> plan-lite -> run-lite 완료 확인
2. Strict 정상 흐름:
   - feature 생성 -> plan-strict -> run-strict 완료 확인(리뷰 포함)
3. READY 없음:
   - plan-lite, plan-strict 각각 `FEATURE_NOT_READY` 즉시 중단 확인
4. READY 2개 이상:
   - plan-lite, plan-strict 각각 `FEATURE_MULTI_READY` 즉시 중단 확인
5. archive 트리거:
   - Lite: 경고 후 루프 지속 확인
   - Strict: 중단 메시지 -> PAUSE 생성 -> rw-archive 실행 -> 재개 가능 확인
6. strict escalate:
   - unresolved `REVIEW-ESCALATE` 존재 시 즉시 중단 확인
7. strict recover:
   - `REVIEW-ESCALATE-RESOLVED` append 후 재개 가능 확인

## Teardown (필수)
1. `/Users/kaya/Documents/Github/context/context-github/.ai/PROGRESS.md`의 `pending/in-progress` TASK가 실제 `/Users/kaya/Documents/Github/context/context-github/.ai/tasks/TASK-*.md`와 1:1 매칭되는지 확인
2. 테스트용 synthetic TASK/REVIEW 로그 제거
3. `/Users/kaya/Documents/Github/context/context-github/.ai/PAUSE.md`, `/Users/kaya/Documents/Github/context/context-github/.ai/ARCHIVE_LOCK` 부재 확인
4. run 재진입 가능 여부 최종 확인

## 증거 보존 순서 (필수)
1. 보고서 파일 먼저 작성: `/Users/kaya/Documents/Github/context/context-github/.ai/notes/ORCH-E2E-REAL-TEST-<YYYYMMDD-HHMM>.md`
2. 보고서에 아래 메타데이터를 기록:
   - 검증 브랜치명
   - 검증 시작/종료 시각
   - 시작 HEAD / 종료 HEAD 커밋 해시
   - `git status --short` 요약
3. 보고서 저장 및 필요 시 커밋 후에만 작업 트리 정리(`git checkout --`, `git restore`) 수행
4. 브랜치 삭제는 최종 판정 공유 이후에만 수행

## 산출물
- `/Users/kaya/Documents/Github/context/context-github/.ai/notes/ORCH-E2E-REAL-TEST-<YYYYMMDD-HHMM>.md`

## 보고서 필수 섹션
1. 시나리오 종합 표(PASS/FAIL)
2. 시나리오별 실행 증거(명령/exit code/핵심 출력/변경 파일)
3. 실패 원인과 수정 내역
4. Teardown 결과
5. 배포 판정:
   - 오케스트라 배포 가능/불가
   - 제품(앱) 배포 가능/불가
   - 각각의 근거 3줄 이내
6. 검증 메타데이터:
   - `branch`
   - `HEAD commit`
   - 증거 보존 완료 여부(yes/no)
