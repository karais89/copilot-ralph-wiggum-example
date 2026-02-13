# Phase 2: rw-plan

Print `SMOKE_PHASE_BEGIN phase=plan`.

Before dispatch:
- Identify one `READY_FOR_PLAN` feature file from `"$TARGET_ROOT/.ai/features/"`.

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/plan-phase1.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`
- `<ACTUAL_FEATURE_FILE_PATH>` => absolute selected feature file path

Expected subagent last line:
- `SMOKE_PLAN_DONE`
- If missing or mismatched: `SMOKE_TEST_FAIL plan: invalid subagent output token`

Gate 2 checks (fail as `SMOKE_TEST_FAIL plan: <detail>`):
- `"$TARGET_ROOT/.ai/tasks/TASK-02-*.md"` exists and contains `## Dependencies`, `## Verification`
- `"$TARGET_ROOT/.ai/tasks/TASK-03-*.md"` exists and contains `## Dependencies`, `## Verification`
- `"$TARGET_ROOT/.ai/PROGRESS.md"` contains `TASK-02` row with `pending`
- `"$TARGET_ROOT/.ai/PROGRESS.md"` contains `TASK-03` row with `pending`
- `"$TARGET_ROOT/.ai/PLAN.md"` Feature Notes section contains the feature slug
- Feature file now has `Status: PLANNED`

Commit:
- `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-plan (smoke)"`
- If git fails: `SMOKE_TEST_FAIL plan: git failed`

Print `SMOKE_GATE_PASS phase=plan`.
