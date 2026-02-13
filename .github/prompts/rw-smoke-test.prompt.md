---
name: rw-smoke-test
description: "E2E smoke test: dispatches subagents to run the full RW pipeline (new-project → plan → run → review → feature → plan → run → review) on a temp project and validates results"
agent: agent
argument-hint: "Optional: absolute path to workspace root. Default: creates temp dir under /tmp."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Automated end-to-end smoke test for the RW orchestration pipeline.
- Creates a temporary project, then dispatches subagents for each RW step.
- Validates file contracts, state transitions, and build results between steps.
- Outputs `SMOKE_TEST_PASS` on success, `SMOKE_TEST_FAIL <phase>` on failure.

Rules:
- Pre-pipeline guards (checked before any phase starts):
  - If not running in a top-level Copilot Chat turn, print `TOP_LEVEL_REQUIRED` and stop. No final-line rule applies.
  - If `#tool:agent/runSubagent` is unavailable, print `RW_ENV_UNSUPPORTED` and stop. No final-line rule applies.
- NON_INTERACTIVE_MODE=true for all subagents (no user questions allowed).
  - Enforcement: every subagent prompt includes `NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.`
- Once the pipeline starts (Setup and beyond), the following output contract applies:
  - On any gate check failure, print `SMOKE_TEST_FAIL <phase-name>: <reason>` as the final line and stop.
  - On any `git` command failure (init, add, commit), print `SMOKE_TEST_FAIL <phase-name>: git failed` as the final line and stop.
  - On success, the **final line** must be `SMOKE_TEST_PASS total_phases=<n> dispatches=<n>`.
  - Intermediate output (gate pass tokens, git log, etc.) is allowed before the final line.

Variable notation contract:
- **Subagent templates** use `<ACTUAL_*>` angle-bracket placeholders (e.g. `<ACTUAL_TARGET_ROOT>`, `<ACTUAL_LOCKED_TASK_ID>`). The orchestrator MUST substitute these with concrete absolute paths / values before dispatching `runSubagent`. Subagents receive only literal strings.
- **Orchestrator instructions** (Setup, Gates, Commits, Final Report) use shell variable syntax `$TARGET_ROOT`, `$TEMPLATE_SOURCE`, etc. These refer to the orchestrator's own resolved local variables. The orchestrator expands them to concrete values when executing shell commands.
- All orchestrator-side file checks/globs must use `"$TARGET_ROOT/.ai/..."` paths (never relative `.ai/...`).

Constants:
- `SMOKE_PROJECT_IDEA=simple hello CLI that greets users by name`
- `SMOKE_FEATURE_IDEA=add goodbye command that says farewell by name`

## Setup

1) Determine `WORKSPACE_ROOT`:
   - If user provided an argument, use that as `WORKSPACE_ROOT`.
   - Otherwise, create a temp directory: run `mktemp -d /tmp/rw-smoke-XXXXXX` and use the result.
2) Determine `TEMPLATE_SOURCE`:
   - The current VS Code workspace root (where this prompt file lives).
3) Run `"$TEMPLATE_SOURCE/scripts/extract-template.sh" "$WORKSPACE_ROOT"`.
   - If it fails, print `SMOKE_TEST_FAIL setup: extract-template.sh failed` and stop.
4) Initialize git:
   - `cd "$WORKSPACE_ROOT" && git init && git add -A && git commit -m "chore: initial extract"`
   - If any git command fails, print `SMOKE_TEST_FAIL setup: git failed` and stop.
5) Set `TARGET_ROOT` = resolved `WORKSPACE_ROOT` (absolute path).
6) Print `SMOKE_SETUP_OK TARGET_ROOT=` followed by the resolved path.

## Phase 1: rw-new-project (subagent)

Print `SMOKE_PHASE_BEGIN phase=new-project`

Dispatch `#tool:agent/runSubagent` with this prompt:

<SMOKE_NEWPROJECT_PROMPT>
You are simulating the rw-new-project workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Run `<ACTUAL_TARGET_ROOT>/scripts/rw-bootstrap-scaffold.sh "<ACTUAL_TARGET_ROOT>"`.
2) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md`.
3) Update `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md`:
   - Set overview to describe this project: SMOKE_PROJECT_IDEA
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
</SMOKE_NEWPROJECT_PROMPT>

### Gate 1: validate new-project results
Before dispatching Phase 1, record the file counts: `CHARTER_COUNT_BEFORE` = number of `"$TARGET_ROOT/.ai/notes/PROJECT-CHARTER-*.md"` files, `FEATURE_COUNT_BEFORE` = number of files in `"$TARGET_ROOT/.ai/features/"` with `Status: READY_FOR_PLAN`.

After subagent returns, check all of the following. If any fails, print `SMOKE_TEST_FAIL new-project: <detail>` and stop.
- `"$TARGET_ROOT/.ai/PLAN.md"` exists and contains `## Feature Notes (append-only)`
- `"$TARGET_ROOT/.ai/PLAN.md"` contains technology stack info (Node.js or TypeScript)
- Number of `PROJECT-CHARTER-*.md` files > `CHARTER_COUNT_BEFORE` (new charter was created)
- Number of feature files with `Status: READY_FOR_PLAN` > `FEATURE_COUNT_BEFORE` (new feature was created)
- The newly created feature file contains `Planning Profile: FAST_TEST`

Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-new-project (smoke)"`
- If git fails, print `SMOKE_TEST_FAIL new-project: git failed` and stop.
Print `SMOKE_GATE_PASS phase=new-project`

## Phase 2: rw-plan (subagent)

Print `SMOKE_PHASE_BEGIN phase=plan`

Identify the `READY_FOR_PLAN` feature file from `"$TARGET_ROOT/.ai/features/"`.

Dispatch `#tool:agent/runSubagent` with this prompt:

<SMOKE_PLAN_PROMPT>
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
</SMOKE_PLAN_PROMPT>

### Gate 2: validate plan results
Check all of the following. If any fails, print `SMOKE_TEST_FAIL plan: <detail>` and stop.
- `"$TARGET_ROOT/.ai/tasks/TASK-02-*.md"` exists with `## Dependencies`, `## Verification`
- `"$TARGET_ROOT/.ai/tasks/TASK-03-*.md"` exists with `## Dependencies`, `## Verification`
- `"$TARGET_ROOT/.ai/PROGRESS.md"` contains `TASK-02` row with `pending` status
- `"$TARGET_ROOT/.ai/PROGRESS.md"` contains `TASK-03` row with `pending` status
- `"$TARGET_ROOT/.ai/PLAN.md"` `Feature Notes` section contains the feature slug
- Feature file now has `Status: PLANNED`

Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-plan (smoke)"`
- If git fails, print `SMOKE_TEST_FAIL plan: git failed` and stop.
Print `SMOKE_GATE_PASS phase=plan`

## Phase 3: rw-run (subagent loop)

Print `SMOKE_PHASE_BEGIN phase=run`

Execute tasks in dependency order: TASK-01, TASK-02, TASK-03.

For TASK-01 (bootstrap-workspace):
- Already completed by scaffold. Mark it `completed` in PROGRESS with the scaffold commit SHA.
- Append log: `TASK-01 completed: workspace bootstrap verified.`
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: mark TASK-01 completed"`
  - If git fails, print `SMOKE_TEST_FAIL run: git failed` and stop.

For each of TASK-02, TASK-03:
- Dispatch `#tool:agent/runSubagent` with the following prompt (substitute all `<ACTUAL_*>` placeholders with concrete values before dispatch):

<SMOKE_RUN_PROMPT>
You are a senior software engineer coding subagent for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
Locked task for this dispatch is `<ACTUAL_LOCKED_TASK_ID>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Rules:
- Read the task file at `<ACTUAL_TARGET_ROOT>/.ai/tasks/<ACTUAL_LOCKED_TASK_ID>-*.md` (glob to find the exact filename).
- Read `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md` for project context.
- Fully implement only `<ACTUAL_LOCKED_TASK_ID>`.
- Read/write only files under `<ACTUAL_TARGET_ROOT>`.
- Never call `#tool:agent/runSubagent` (nested calls disallowed).
- Run build/verification commands from the task file; if issues are found, fix them (up to 2 retries).
- Update `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md`: change `<ACTUAL_LOCKED_TASK_ID>` status to `completed`, add commit SHA, append a Log entry.
- Do not change status for any other task.
- Commit changes with a conventional commit message.

Output contract (last line):
- `SMOKE_RUN_TASK_DONE <ACTUAL_LOCKED_TASK_ID>`
</SMOKE_RUN_PROMPT>

After each subagent dispatch:
- Re-read PROGRESS and verify the dispatched task's status is now `completed`.
- If not, print `SMOKE_TEST_FAIL run: <dispatched-task-id> not completed after dispatch` and stop.

### Gate 3: validate run results
Check:
- All 3 tasks (TASK-01, TASK-02, TASK-03) show `completed` in PROGRESS.
- `npm run build` succeeds (run in `"$TARGET_ROOT"`).
- `node dist/index.js greet World` outputs `Hello, World!`.
- If build or output check fails, print `SMOKE_TEST_FAIL run: build/output verification failed` and stop.

Print `SMOKE_GATE_PASS phase=run`

## Phase 4: rw-review (subagent)

Print `SMOKE_PHASE_BEGIN phase=review`

Dispatch `#tool:agent/runSubagent` with:

<SMOKE_REVIEW_PROMPT>
You are a task reviewer subagent for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md` and identify all `completed` tasks.
2) For each completed task (`TASK-01`, `TASK-02`, `TASK-03`):
   - Read the task file from `<ACTUAL_TARGET_ROOT>/.ai/tasks/`.
   - Run the `Verification` commands listed in the task file.
   - Record result as OK or FAIL with root cause.
3) Do NOT modify any repository files.

Output contract:
- For each task, print one line: `REVIEW_RESULT TASK-XX OK` or `REVIEW_RESULT TASK-XX FAIL: <reason>`
- Last line: `SMOKE_REVIEW_DONE ok=<n> fail=<n>`
</SMOKE_REVIEW_PROMPT>

After subagent returns:
- Parse subagent output for `REVIEW_RESULT` lines.
- For each OK result, append to PROGRESS Log: `REVIEW_OK TASK-XX: verification passed`
- For each FAIL result, append: `REVIEW_FAIL TASK-XX (1/3): <reason>`
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: rw-review (smoke)"`
  - If git fails, print `SMOKE_TEST_FAIL review: git failed` and stop.

### Gate 4: validate review results
- All 3 tasks have `REVIEW_OK` in PROGRESS Log.
- If any FAIL, print `SMOKE_TEST_FAIL review: <failed-task-ids>` and stop.

Print `SMOKE_GATE_PASS phase=review`

## Phase 5: rw-feature (subagent)

Print `SMOKE_PHASE_BEGIN phase=feature`

Dispatch `#tool:agent/runSubagent` with:

<SMOKE_FEATURE_PROMPT>
You are simulating the rw-feature workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md`.
2) Create a new feature file `<ACTUAL_TARGET_ROOT>/.ai/features/<YYYYMMDD-HHMM>-add-goodbye-command.md`:
   - `Status: READY_FOR_PLAN`
   - `Planning Profile: FAST_TEST`
   - Feature summary: add goodbye command that says farewell by name
   - Need statement: User wants to say goodbye. Desired outcome: `hello goodbye <name>` → "Goodbye, <name>!"
   - Acceptance: `npm run build && node dist/index.js goodbye World`
3) Do NOT modify PLAN, PROGRESS, or any task files.
4) Do NOT create git commits.

Output contract (last line):
- `SMOKE_FEATURE_DONE`
</SMOKE_FEATURE_PROMPT>

### Gate 5: validate feature results
Before dispatching Phase 5, record `FEATURE_COUNT_BEFORE` = number of feature files with `Status: READY_FOR_PLAN`.
After subagent returns, check the following. If any fails, print `SMOKE_TEST_FAIL feature: <detail>` and stop.
- Number of feature files with `Status: READY_FOR_PLAN` > `FEATURE_COUNT_BEFORE` (new feature was created)
- The newly created feature file contains `goodbye`

Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-feature (smoke)"`
- If git fails, print `SMOKE_TEST_FAIL feature: git failed` and stop.
Print `SMOKE_GATE_PASS phase=feature`

## Phase 6: rw-plan (subagent, feature 2)

Print `SMOKE_PHASE_BEGIN phase=plan-2`

Identify the new `READY_FOR_PLAN` feature file.

Dispatch `#tool:agent/runSubagent` with:

<SMOKE_PLAN2_PROMPT>
You are simulating the rw-plan workflow for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/CONTEXT.md` and the new feature file at `<ACTUAL_FEATURE_FILE_PATH>`.
2) Since `Planning Profile: FAST_TEST`, create 2-3 task files for the goodbye feature.
   - Required: `TASK-04-goodbye-command.md`: Add `goodbye <name>` command.
     - Dependencies: TASK-03
     - Verification: `npm run build && node dist/index.js goodbye World`
   - Additional tasks optional (e.g. tests, docs). Total 2-3 per FAST_TEST policy.
3) Append Feature Notes entry to `<ACTUAL_TARGET_ROOT>/.ai/PLAN.md`.
4) Add new task rows as `pending` to `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md` Task Status.
5) Append a Log entry to `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md`.
6) Change feature file status to `PLANNED`.
7) Do NOT create git commits.

Output contract (last line):
- `SMOKE_PLAN2_DONE`
</SMOKE_PLAN2_PROMPT>

### Gate 6: validate plan-2 results
Before dispatching Phase 6, record `TASK_COUNT_BEFORE` = number of `TASK-*.md` files in `"$TARGET_ROOT/.ai/tasks/"`.
After subagent returns, check the following. If any fails, print `SMOKE_TEST_FAIL plan-2: <detail>` and stop.
- `TASK_COUNT_AFTER - TASK_COUNT_BEFORE` is 2 or 3 (matching FAST_TEST policy)
- PROGRESS has the new task row(s) with `pending`
- Feature file status is `PLANNED`

Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "feat: rw-plan-2 (smoke)"`
- If git fails, print `SMOKE_TEST_FAIL plan-2: git failed` and stop.

After Gate 6 passes, collect the list of newly created `pending` task IDs (e.g. TASK-04, TASK-05, ...) into `PLAN2_TASK_IDS`.
Print `SMOKE_GATE_PASS phase=plan-2`

## Phase 7: rw-run (subagent, plan-2 tasks)

Print `SMOKE_PHASE_BEGIN phase=run-2`

For each task ID in `PLAN2_TASK_IDS` (in dependency order):
- Dispatch `#tool:agent/runSubagent` with SMOKE_RUN_PROMPT (same template as Phase 3), substituting the current task ID into `<ACTUAL_LOCKED_TASK_ID>`.
- After each dispatch, verify the task status changed to `completed` in PROGRESS.
- If not, print `SMOKE_TEST_FAIL run-2: <task-id> not completed after dispatch` and stop.

### Gate 7: validate run-2 results
Check the following. If any fails, print `SMOKE_TEST_FAIL run-2: <detail>` and stop.
- All tasks in `PLAN2_TASK_IDS` show `completed` in PROGRESS.
- `npm run build` succeeds.
- `node dist/index.js goodbye World` outputs `Goodbye, World!`.
- `node dist/index.js greet World` still outputs `Hello, World!` (non-destructive check).

Print `SMOKE_GATE_PASS phase=run-2`

## Phase 8: rw-review (subagent, plan-2 tasks)

Print `SMOKE_PHASE_BEGIN phase=review-2`

Dispatch `#tool:agent/runSubagent` with:

<SMOKE_REVIEW2_PROMPT>
You are a task reviewer subagent for a smoke test.
Target project root is `<ACTUAL_TARGET_ROOT>`.
NON_INTERACTIVE_MODE=true — do not ask questions, do not call askQuestions, use safe defaults for any missing input.

Steps:
1) Read `<ACTUAL_TARGET_ROOT>/.ai/PROGRESS.md` and identify newly `completed` tasks from Phase 7.
2) For each newly completed task, read the task file and run its Verification commands.
3) Also verify that existing `greet` command still works (non-destructive).
4) Do NOT modify any repository files.

Output contract:
- For each reviewed task: `REVIEW_RESULT TASK-XX OK` or `REVIEW_RESULT TASK-XX FAIL: <reason>`
- Last line: `SMOKE_REVIEW2_DONE ok=<n> fail=<n>`
</SMOKE_REVIEW2_PROMPT>

After subagent returns:
- Parse result and append `REVIEW_OK TASK-XX` or `REVIEW_FAIL TASK-XX` for each reviewed task to PROGRESS.
- Commit: `cd "$TARGET_ROOT" && git add -A && git commit -m "chore: rw-review-2 (smoke)"`
  - If git fails, print `SMOKE_TEST_FAIL review-2: git failed` and stop.

### Gate 8: validate review-2 results
- All newly completed tasks from Phase 7 have `REVIEW_OK` in PROGRESS Log.
- If any FAIL, print `SMOKE_TEST_FAIL review-2: <failed-task-ids>` and stop.

Print `SMOKE_GATE_PASS phase=review-2`

## Final Report

Print git log summary: `cd "$TARGET_ROOT" && git log --oneline`
Print: `TARGET_ROOT="$TARGET_ROOT"`
Print: `✅ RW smoke test completed successfully. All phases passed.`

Final line (must be the very last line of output):
`SMOKE_TEST_PASS total_phases=8 dispatches=<total-subagent-dispatches>`
