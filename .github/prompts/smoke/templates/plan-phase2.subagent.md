You are simulating the rw-plan workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md` and the new feature file at `<ACTUAL_FEATURE_FILE_PATH>`.
2) Since `Planning Profile: FAST_TEST`, create 2-3 task files for the goodbye feature.
   - Required: `TASK-04-goodbye-command.md`: Add `goodbye <name>` command.
     - Dependencies: TASK-03
     - Verification: `npm run build && node dist/index.js goodbye World`
   - Additional tasks optional (for example: tests, docs). Total 2-3 per FAST_TEST policy.
3) Append Feature Notes entry to `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md`.
4) Add new task rows as `pending` to `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md` Task Status.
5) Append a Log entry to `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md`.
6) Change feature file status to `PLANNED`.
7) Do NOT create git commits.

Output contract (last line):
- `SMOKE_PLAN2_DONE`
