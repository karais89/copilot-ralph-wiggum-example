You are simulating the rw-feature workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md`.
2) Create a new feature file `<ACTUAL_TARGET_ROOT>/.ai/features/<YYYYMMDD-HHMM>-add-goodbye-command.md`:
   - `Status: READY_FOR_PLAN`
   - `Planning Profile: FAST_TEST`
   - Feature summary: add goodbye command that says farewell by name
   - Need statement: User wants to say goodbye. Desired outcome: `hello goodbye <name>` -> "Goodbye, <name>!"
   - Acceptance: `npm run build && node dist/index.js goodbye World`
3) Do NOT modify PLAN, PROGRESS, or any task files.
4) Do NOT create git commits.

Output contract (last line):
- `SMOKE_FEATURE_DONE`
