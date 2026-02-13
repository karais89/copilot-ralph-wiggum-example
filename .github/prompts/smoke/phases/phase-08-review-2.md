# Phase 8: rw-review (plan-2 tasks)

Print `SMOKE_PHASE_BEGIN phase=review-2`.

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/review-phase2.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`

Expected subagent last line:
- `SMOKE_REVIEW2_DONE ok=<n> fail=<n>`
- If missing or mismatched: `SMOKE_TEST_FAIL review-2: invalid subagent output token`

After subagent returns:
- Parse `REVIEW_RESULT TASK-XX OK` / `REVIEW_RESULT TASK-XX FAIL: <reason>` lines.
- Append `REVIEW_OK TASK-XX` or `REVIEW_FAIL TASK-XX` entries for reviewed tasks to `"$TARGET_ROOT/.ai/PROGRESS.md"` log.
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: rw-review-2 (smoke)"`
- If git fails: `SMOKE_TEST_FAIL review-2: git failed`

Gate 8 checks (fail as `SMOKE_TEST_FAIL review-2: <detail>`):
- All newly completed tasks from Phase 7 have `REVIEW_OK` in PROGRESS log
- If any FAIL exists: `SMOKE_TEST_FAIL review-2: <failed-task-ids>`

Print `SMOKE_GATE_PASS phase=review-2`.
