You are simulating the rw-plan workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md`.
2) Read the feature file at `<ACTUAL_FEATURE_FILE_PATH>`.
3) Deterministic baseline for this first cycle: create exactly 2 task files (`TASK-02`, `TASK-03`):
   - `TASK-02-init-project.md`: Initialize Node.js + TypeScript project (package.json, tsconfig.json, .gitignore).
     - Dependencies: TASK-01
     - Verification: `npm install && npx tsc --version`
   - `TASK-03-cli-greet-command.md`: Implement `greet <name>` command with Commander.js.
     - Dependencies: TASK-02
     - Verification: `npm run build && node dist/index.js greet World`
   - Each task file follows the standard template: `# TASK-XX: title`, `## Dependencies`, `## Description`, `## Acceptance Criteria`, `## Files to Create/Modify`, `## Verification`
4) Append a Feature Notes entry to `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md`:
   - `- <YYYY-MM-DD>: [<feature-slug>] <summary>. Related tasks: TASK-02~TASK-03.`
5) Update `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md`:
   - Add `TASK-02` and `TASK-03` rows as `pending` to the Task Status table.
   - Append a Log entry for the plan action.
6) Update the feature file: change `Status: READY_FOR_PLAN` to `Status: PLANNED`.
7) Do NOT create git commits.

Output contract (last line):
- `SMOKE_PLAN_DONE`
