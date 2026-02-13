# Phase 4: rw-review

Print `SMOKE_PHASE_BEGIN phase=review`.

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/review-phase1.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`

Expected subagent last line:
- `SMOKE_REVIEW_DONE ok=<n> fail=<n>`
- If missing or mismatched: `SMOKE_TEST_FAIL review: invalid subagent output token`

After subagent returns:
- Parse `REVIEW_RESULT TASK-XX OK` / `REVIEW_RESULT TASK-XX FAIL: <reason>` lines.
- For each OK: append `REVIEW_OK TASK-XX: verification passed` to `"$TARGET_ROOT/.ai/PROGRESS.md"` log.
- For each FAIL: append `REVIEW_FAIL TASK-XX (1/3): <reason>` to `"$TARGET_ROOT/.ai/PROGRESS.md"` log.
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: rw-review (smoke)"`
- If git fails: `SMOKE_TEST_FAIL review: git failed`

Gate 4 checks (fail as `SMOKE_TEST_FAIL review: <detail>`):
- `TASK-01`, `TASK-02`, `TASK-03` all have `REVIEW_OK` in PROGRESS log
- If any FAIL exists: `SMOKE_TEST_FAIL review: <failed-task-ids>`

Print `SMOKE_GATE_PASS phase=review`.
