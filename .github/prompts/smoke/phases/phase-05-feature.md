# Phase 5: rw-feature

Print `SMOKE_PHASE_BEGIN phase=feature`.

Before dispatch:
- `FEATURE_COUNT_BEFORE` = number of feature files with `Status: READY_FOR_PLAN` in `"$TARGET_ROOT/.ai/features/"`

Dispatch `#tool:agent/runSubagent` with template file:
- `"$PROMPT_ROOT/smoke/templates/feature.subagent.md"`

Placeholder substitution:
- `<ACTUAL_TARGET_ROOT>` => absolute `TARGET_ROOT`

Expected subagent last line:
- `SMOKE_FEATURE_DONE`
- If missing or mismatched: `SMOKE_TEST_FAIL feature: invalid subagent output token`

Gate 5 checks (fail as `SMOKE_TEST_FAIL feature: <detail>`):
- Number of feature files with `Status: READY_FOR_PLAN` is greater than `FEATURE_COUNT_BEFORE`
- Newly created feature file contains `goodbye`

Commit:
- `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-feature (smoke)"`
- If git fails: `SMOKE_TEST_FAIL feature: git failed`

Print `SMOKE_GATE_PASS phase=feature`.
