# Phase 7: rw-run (plan-2 tasks)

Print `SMOKE_PHASE_BEGIN phase=run-2`.

For each task ID in `PLAN2_TASK_IDS` (dependency order):
- Dispatch `#tool:agent/runSubagent` with:
  - `"$PROMPT_ROOT/smoke/templates/run-task.subagent.md"`
- Placeholder substitution:
  - `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`
  - `<ACTUAL_LOCKED_TASK_ID>` => current task ID
- Expected subagent last line:
  - `SMOKE_RUN_TASK_DONE <ACTUAL_LOCKED_TASK_ID>`
- If missing or mismatched: `SMOKE_TEST_FAIL run-2: invalid subagent output token for <task-id>`
- After dispatch, verify current task status is `completed` in `"$TARGET_ROOT/.ai/PROGRESS.md"`.
- If not completed: `SMOKE_TEST_FAIL run-2: <task-id> not completed after dispatch`

Gate 7 checks (fail as `SMOKE_TEST_FAIL run-2: <detail>`):
- All task IDs in `PLAN2_TASK_IDS` show `completed` in PROGRESS
- `npm run build` succeeds
- `node dist/index.js goodbye World` outputs `Goodbye, World!`
- `node dist/index.js greet World` still outputs `Hello, World!`

Print `SMOKE_GATE_PASS phase=run-2`.
