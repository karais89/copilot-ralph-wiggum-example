# RW Smoke Contract

Language policy reference: `.ai/CONTEXT.md`

Pre-pipeline guards (checked before any phase starts):
- If not running in a top-level Copilot Chat turn, print `TOP_LEVEL_REQUIRED` and stop.
- If `#tool:agent/runSubagent` is unavailable, print `RW_ENV_UNSUPPORTED` and stop.

Subagent interaction rules:
- Set `NON_INTERACTIVE_MODE=true` for all subagent dispatches.
- Every subagent prompt must include this line exactly:
  - `NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.`
- Nested subagent calls are disallowed. Any run-task template must keep `Never call #tool:agent/runSubagent`.

Output contract once pipeline starts (Setup and beyond):
- On any gate failure, print `SMOKE_TEST_FAIL <phase-name>: <reason>` as the final line and stop.
- On any `git` failure (`init`, `add`, `commit`), print `SMOKE_TEST_FAIL <phase-name>: git failed` as the final line and stop.
- On success, the final line must be:
  - `SMOKE_TEST_PASS total_phases=<n> dispatches=<n>`
- Intermediate output is allowed before the final line.

Result artifact contract (applies after `TARGET_ROOT` is resolved):
- Persist final smoke results in both files:
  - `"$TARGET_ROOT/.ai/runtime/smoke/last-result.json"`
  - `"$TARGET_ROOT/.ai/runtime/smoke/last-result.md"`
- Before printing a terminal final line (`SMOKE_TEST_PASS...` or `SMOKE_TEST_FAIL...`), update both artifacts first.
- Required JSON fields:
  - `status` (`PASS` or `FAIL`)
  - `timestamp` (UTC ISO-8601)
  - `target_root`
  - `git_head`
  - `total_phases`
  - `dispatches`
  - `failed_phase` (`null` on PASS)
  - `reason` (`null` on PASS)
  - `checks.build.status`, `checks.greet.status`, `checks.goodbye.status`, `checks.test.status` (`PASS|FAIL|SKIPPED`)
  - `checks.<name>.detail` (short command/output summary)
- If failure occurs before final report, write fail artifacts with the best known values (unknown values may be set to `null`), then print `SMOKE_TEST_FAIL ...` and stop.
- If no test command is available, set `checks.test.status` to `SKIPPED`.

Variable notation contract:
- Subagent templates use `<ACTUAL_*>` placeholders.
- Orchestrator must substitute placeholders with literal concrete values before dispatch.
- Orchestrator instructions use local shell-style names like `$TARGET_ROOT`, `$PROMPT_ROOT`.
- All orchestrator-side checks/globs must use `"$TARGET_ROOT/.ai/..."` paths, never relative `.ai/...`.

Shared constants:
- `SMOKE_PROJECT_IDEA=simple hello CLI that greets users by name`
- `SMOKE_FEATURE_IDEA=add goodbye command that says farewell by name`

Shared template dispatch contract:
- Load template text from `"$PROMPT_ROOT/smoke/templates/*.subagent.md"`.
- Replace all required placeholders (`<ACTUAL_TARGET_ROOT>`, `<ACTUAL_FEATURE_FILE_PATH>`, `<ACTUAL_LOCKED_TASK_ID>`) before dispatch.
- Preserve template content/ordering; only placeholder substitution is allowed.
- Validate the template's expected last-line token after each dispatch.
