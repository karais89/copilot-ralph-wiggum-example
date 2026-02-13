# Phase 1: rw-new-project

Print `SMOKE_PHASE_BEGIN phase=new-project`.

Before dispatch:
- `CHARTER_COUNT_BEFORE` = count of `"$TARGET_ROOT/.ai/notes/PROJECT-CHARTER-*.md"`
- `FEATURE_COUNT_BEFORE` = count of files in `"$TARGET_ROOT/.ai/features/"` with `Status: READY_FOR_PLAN`

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/new-project.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`

Expected subagent last line:
- `SMOKE_NEWPROJECT_DONE`
- If missing or mismatched: `SMOKE_TEST_FAIL new-project: invalid subagent output token`

Gate 1 checks (fail as `SMOKE_TEST_FAIL new-project: <detail>`):
- `"$TARGET_ROOT/.ai/PLAN.md"` exists and contains `## Feature Notes (append-only)`
- `"$TARGET_ROOT/.ai/PLAN.md"` contains technology stack info (`Node.js` or `TypeScript`)
- Number of `PROJECT-CHARTER-*.md` files is greater than `CHARTER_COUNT_BEFORE`
- Number of feature files with `Status: READY_FOR_PLAN` is greater than `FEATURE_COUNT_BEFORE`
- Newly created feature file contains `Planning Profile: FAST_TEST`

Commit:
- `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-new-project (smoke)"`
- If git fails: `SMOKE_TEST_FAIL new-project: git failed`

Print `SMOKE_GATE_PASS phase=new-project`.
