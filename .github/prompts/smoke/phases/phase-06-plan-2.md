# Phase 6: rw-plan (feature 2)

Print `SMOKE_PHASE_BEGIN phase=plan-2`.

Before dispatch:
- `TASK_COUNT_BEFORE` = number of `TASK-*.md` files in `"$TARGET_ROOT/.ai/tasks/"`
- Identify the new `READY_FOR_PLAN` feature file.

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/plan-phase2.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`
- `<ACTUAL_FEATURE_FILE_PATH>` => absolute selected feature file path

Expected subagent last line:
- `SMOKE_PLAN2_DONE`
- If missing or mismatched: `SMOKE_TEST_FAIL plan-2: invalid subagent output token`

Gate 6 checks (fail as `SMOKE_TEST_FAIL plan-2: <detail>`):
- `TASK_COUNT_AFTER - TASK_COUNT_BEFORE` is 2 or 3
- `"$TARGET_ROOT/.ai/PROGRESS.md"` has new task row(s) with `pending`
- Feature file status is `PLANNED`

Commit:
- `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-plan-2 (smoke)"`
- If git fails: `SMOKE_TEST_FAIL plan-2: git failed`

After Gate 6:
- Collect newly created pending task IDs into `PLAN2_TASK_IDS` (for example: `TASK-04`, `TASK-05`).

Print `SMOKE_GATE_PASS phase=plan-2`.
