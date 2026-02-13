You are simulating the rw-new-project workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Run `<ACTUAL_TARGET_ROOT>/scripts/rw-bootstrap-scaffold.sh "<ACTUAL_TARGET_ROOT>"`.
2) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md`.
3) Update `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md`:
   - Set overview to describe this project: simple hello CLI that greets users by name
   - Technology stack: Node.js >= 18, TypeScript (strict mode), Commander.js
   - Ensure `## Feature Notes (append-only)` section exists.
4) Create `<ACTUAL_TARGET_ROOT>/.ai/notes/PROJECT-CHARTER-<YYYYMMDD>.md`:
   - Project summary, MVP scope, constraints, verification baseline.
5) Create one bootstrap feature file `<ACTUAL_TARGET_ROOT>/.ai/features/<YYYYMMDD-HHMM>-bootstrap-foundation.md`:
   - `Status: READY_FOR_PLAN`
   - `Planning Profile: FAST_TEST`
   - Summary, need statement, goal, scope, acceptance criteria.
6) Do NOT create TASK files. Do NOT create git commits.

Output contract (last line):
- `SMOKE_NEWPROJECT_DONE`
