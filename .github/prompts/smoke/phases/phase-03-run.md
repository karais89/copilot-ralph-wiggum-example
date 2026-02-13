# Phase 3: rw-run

Print `SMOKE_PHASE_BEGIN phase=run`.

Execution order:
- `TASK-01`, `TASK-02`, `TASK-03`

For `TASK-01`:
- Mark `TASK-01` as `completed` in `"$TARGET_ROOT/.ai/PROGRESS.md"` using scaffold commit SHA.
- Append log: `TASK-01 completed: workspace bootstrap verified.`
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: mark TASK-01 completed"`
- If git fails: `SMOKE_TEST_FAIL run: git failed`

For each of `TASK-02`, `TASK-03`:
- Dispatch `#tool:agent/runSubagent` with:
  - `"$PROMPT_ROOT/smoke/templates/run-task.subagent.md"`
- Placeholder substitution:
  - `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`
  - `<ACTUAL_LOCKED_TASK_ID>` => current task ID
- Expected subagent last line:
  - `SMOKE_RUN_TASK_DONE <ACTUAL_LOCKED_TASK_ID>`
- If missing or mismatched: `SMOKE_TEST_FAIL run: invalid subagent output token for <task-id>`
- After dispatch, re-read `"$TARGET_ROOT/.ai/PROGRESS.md"` and verify current task is `completed`.
- If not completed: `SMOKE_TEST_FAIL run: <task-id> not completed after dispatch`

Gate 3 checks (fail as `SMOKE_TEST_FAIL run: <detail>`):
- `TASK-01`, `TASK-02`, `TASK-03` all show `completed` in PROGRESS
- `npm run build` succeeds in `"$TARGET_ROOT"`
- `node dist/index.js greet World` outputs `Hello, World!`
- On build/output failure: `SMOKE_TEST_FAIL run: build/output verification failed`

Print `SMOKE_GATE_PASS phase=run`.
