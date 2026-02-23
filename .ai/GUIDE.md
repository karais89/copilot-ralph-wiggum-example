# RW 빠른 가이드

이 문서는 현재 RW 워크플로우의 최소 운영 경로만 설명한다.

## 핵심 루프

기본 루프:

1. `rw-feature` (또는 신규는 `rw-new-project`, 기존은 `rw-onboard-project`)
2. `rw-plan`
3. `rw-run`
4. `rw-review`
5. 필요 시 `rw-archive`

## 현재 핵심 프롬프트

- `.github/prompts/rw-new-project.prompt.md`
- `.github/prompts/rw-onboard-project.prompt.md`
- `.github/prompts/rw-feature.prompt.md`
- `.github/prompts/rw-plan.prompt.md`
- `.github/prompts/rw-run.prompt.md`
- `.github/prompts/rw-review.prompt.md`
- `.github/prompts/rw-archive.prompt.md`

오케스트레이터 진입점:

- `.github/agents/rw-orchestrator.agent.md`

## 핵심 스크립트

- `scripts/orchestration/rw-bootstrap-scaffold.sh`
- `scripts/orchestration/rw-resolve-target-root.sh`
- `scripts/rw-smoke-test.sh`
- `scripts/validation/check-prompts.mjs`

보조:

- `scripts/rw` (`status`, `next`)
- `scripts/validation/validate-smoke-result.sh`

## Target Root 규칙

`rw-run`, `rw-review`, `rw-archive`, `rw-orchestrator`는 동일한 target root를 사용해야 한다.

- 해석 계약: `.github/prompts/shared/RW-TARGET-ROOT-RESOLUTION.md`
- 해석 스크립트: `scripts/orchestration/rw-resolve-target-root.sh`

수동 설정 예시:

```bash
./scripts/orchestration/rw-resolve-target-root.sh set-active "$(pwd)" my-project "/absolute/path/to/project"
./scripts/orchestration/rw-resolve-target-root.sh resolve-active "$(pwd)"
```

## 운영 체크리스트

1. Step 0을 건너뛰지 않는다 (`.ai/CONTEXT.md` 선읽기).
2. `Task Status`, `Log`, `pending/in-progress/completed` 토큰을 변경하지 않는다.
3. `rw-plan`만 태스크를 생성하고, `rw-run`은 구현만 수행한다.
4. `rw-run`은 한 번에 한 task만 완료해야 한다.
5. 검증 로그는 `VERIFICATION_EVIDENCE ...` 형식으로 남긴다.
6. 리뷰 실패/에스컬레이션은 `rw-review` 토큰 계약을 따른다.

## 검증

프롬프트/계약 검증:

```bash
node scripts/validation/check-prompts.mjs
```

통합 스모크:

```bash
./scripts/rw-smoke-test.sh
```

## 트러블슈팅

- `LANG_POLICY_MISSING`: `.ai/CONTEXT.md` 누락/읽기 실패. 파일 복구 후 재실행.
- `RW_TARGET_ROOT_INVALID`: target root 해석 실패. 포인터/레지스트리 파일 확인.
- `RW_DOCTOR_BLOCKED`: 실행 환경(runSubagent/git/.ai) 블로커 해결 후 `rw-run` 재실행.
- `REVIEW_PHASE_PRECHECK_FAIL`: 태스크 파일의 `Test Strategy`/`Verification` 섹션 보강 후 재실행.
