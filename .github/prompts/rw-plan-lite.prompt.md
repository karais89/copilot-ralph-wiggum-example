---
name: rw-plan-lite
description: "Ralph Lite: add one feature by appending Feature Notes + creating TASK files + syncing PROGRESS"
agent: agent
argument-hint: "No inline input. Prepare .ai/features/YYYYMMDD-HHMM-<slug>.md with Status: READY_FOR_PLAN."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Append one feature note to `PLAN.md`.
- Create new atomic `TASK-XX-*.md` files without renumbering existing tasks.
  - Default features: 3-6 tasks
  - Bootstrap foundation features: 10-20 tasks (5 allowed only when clearly very small/simple)
- Add only new `pending` rows to `PROGRESS.md`.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

You are adding one feature to an existing Ralph Lite orchestration workspace.

Target files:
- .ai/PLAN.md
- .ai/tasks/TASK-XX-*.md
- .ai/PROGRESS.md
- .ai/features/*.md (selected READY_FOR_PLAN file, status update to PLANNED)

Rules:
- Do not rewrite the whole PLAN.md.
- Update PLAN.md only in `## Feature Notes (append-only)`.
- Do not renumber or edit existing TASK IDs/files unless explicitly asked.
- Do not implement product code.
- Resolve user-document language from `.ai/CONTEXT.md` before writing task/progress prose (default Korean if ambiguous).
- Keep machine/parser tokens and section headers unchanged (`Task Status`, `Log`, `pending`, `Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Verification`).
- In `.ai/tasks/*.md` and PROGRESS `Title` cells, write human-readable values in the resolved user-document language.
- Task sizing rule:
  - Each task should be independently deliverable in roughly 30~120 minutes.
  - If likely >120 minutes, split; if <30 minutes and not independently valuable, merge.
- Verification rule:
  - Each task must include at least one concrete verification command in `Verification`.
- Non-interactive mode:
  - Enable when either:
    - `.tmp/rw-noninteractive.flag` exists.
  - In this mode, never call `#tool:vscode/askQuestions` and never ask interactive follow-up questions.
  - Resolve selection/clarification with deterministic defaults and continue.

Feature input resolution (required):
1) Determine `NON_INTERACTIVE_MODE`:
   - true if `.tmp/rw-noninteractive.flag` exists.
2) Read `.ai/features/`.
3) If `.ai/features/` is missing or unreadable, stop immediately and print:
   - first line exactly: `FEATURES_DIR_MISSING`
   - then a short fix guide:
     - run `.github/prompts/rw-feature.prompt.md` first (recommended)
     - create directory `.ai/features/`
     - create one feature file from `.ai/features/FEATURE-TEMPLATE.md`
     - save as `YYYYMMDD-HHMM-<slug>.md`
     - set `Status: READY_FOR_PLAN`
4) Build input-file candidates from `.ai/features/*.md`, excluding:
   - `FEATURE-TEMPLATE.md`
   - `README.md`
5) If no input-file candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_FILE_MISSING`
   - then a short fix guide:
     - run `.github/prompts/rw-feature.prompt.md` to create one READY file (recommended)
     - copy `.ai/features/FEATURE-TEMPLATE.md` to `.ai/features/YYYYMMDD-HHMM-<slug>.md`
     - set `Status: READY_FOR_PLAN`
6) From input-file candidates, select files with exact line: `Status: READY_FOR_PLAN`.
7) If no READY candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_NOT_READY`
   - then a short fix guide:
     - open the latest `YYYYMMDD-HHMM-<slug>.md`
     - change `Status: DRAFT` (or current value) to `Status: READY_FOR_PLAN`
8) If multiple READY candidates exist:
   - If `NON_INTERACTIVE_MODE=true`, select the latest READY filename by lexical sort and continue.
   - If `NON_INTERACTIVE_MODE=false`, resolve selection interactively (single choice):
     - Use `#tool:vscode/askQuestions` once with one single-choice question:
       - "Multiple READY_FOR_PLAN feature files were found. Which file should be planned now?"
       - Choices: each READY filename + `CANCEL`
     - If `#tool:vscode/askQuestions` is unavailable, ask the same single-choice selection in chat once.
     - If one filename is selected, use that file as the input source.
     - If user selects `CANCEL` or no valid selection is obtained after that single interaction, stop immediately and print:
       - first line exactly: `FEATURE_MULTI_READY`
       - then a short fix guide:
         - keep exactly one file as `Status: READY_FOR_PLAN`
         - set other READY files to `Status: DRAFT` (or `Status: PLANNED` if already consumed)
9) If exactly one READY candidate exists, select that file.
10) Expected input filename pattern: `YYYYMMDD-HHMM-<slug>.md`.
11) In any unresolved error case above, stop immediately without additional clarification questions.

Normalization rules:
1) Backward compatibility: if resolved input already includes structured sections (`goal`, `constraints`, `acceptance`), preserve and use them.
2) If resolved input is a one-line summary, normalize to:
   - Goal: that one-line summary.
   - Constraints (defaults):
     - Keep existing commands/behavior backward-compatible.
     - Minimize scope and file changes to only what is necessary.
     - Project-defined canonical validation commands must pass (language/toolchain agnostic).
   - Acceptance (defaults):
     - User-facing behavior for the goal is implemented and invokable.
     - Error paths return clear user-friendly messages.
     - At least one canonical verification command succeeds with exit code 0.
     - Verification evidence includes command, exit code, and 1-2 key output lines.

Workflow:
1) Ensure baseline workspace files exist before planning:
   - If `.ai/PLAN.md` is missing, create a minimal skeleton with:
     - `# Workspace Plan`
     - `## Overview`
     - one short line: `rw-plan initialized PLAN.md because it was missing.`
     - `## Feature Notes (append-only)` (empty section)
   - If `.ai/PROGRESS.md` is missing, create:
     - `# Progress`
     - `## Task Status`
     - `| Task | Title | Status | Commit |`
     - `|------|-------|--------|--------|`
     - `## Log`
   - Then read `.ai/PLAN.md`, `.ai/PROGRESS.md`, and list existing `.ai/tasks/TASK-*.md` filenames.
2) Resolve feature input using the required precedence rules above.
3) Clarification-first planning:
   - If `NON_INTERACTIVE_MODE=true`, skip interactive rounds and apply defaults (`AI_DECIDE` equivalent).
   - If `NON_INTERACTIVE_MODE=false`, after feature input is resolved, run 2~5 clarification rounds when ambiguity remains.
   - Ask 1~3 focused questions per round (single-choice preferred when practical).
   - Resolve at least before decomposition (unless user selects `AI_DECIDE`):
     - implementation/module boundaries
     - dependency/order constraints between tasks
     - verification commands and pass criteria
     - out-of-scope boundaries
     - risk-sensitive constraints (compatibility, migration, rollback)
   - Do not stop questioning early if high-impact ambiguity remains and round budget is available.
   - If details are sufficient early, proceed immediately.
4) Build a normalized feature spec (`Goal`, `Constraints`, `Acceptance`) using resolved input.
   - Apply defaults only when user explicitly chooses `AI_DECIDE` or clarification budget is exhausted.
5) Append one new Feature Notes line to PLAN.md in this format:
   - YYYY-MM-DD: [feature-slug] Goal/constraints in 1-3 lines. Related tasks: TASK-XX~TASK-YY.
6) Determine next available TASK number from existing task files (max + 1).
7) Create new atomic task files for the feature under `.ai/tasks/` as `TASK-XX-<slug>.md`.
  - Task count policy:
    - Default features: 3~6 tasks.
    - Bootstrap foundation features (slug/name indicates bootstrap+foundation): 10~20 tasks.
    - If bootstrap scope is clearly very small/simple, 5 tasks are allowed.
   Each file must include:
   - Title
   - Dependencies
   - Description
   - Acceptance Criteria
   - Files to Create/Modify
   - Verification
     - Use project-defined commands (do not hardcode language-specific tools unless the project is explicitly language-specific).
     - Require evidence format: `command`, `exit code`, `key output`.
     - Include at least one concrete command per task.
   - Keep the section headers above exactly as written, but write each section value/prose in the resolved user-document language.
8) Update `.ai/PROGRESS.md` Task Status table by adding only new rows as `pending` with commit `-`.
   Keep existing rows unchanged.
   - Use the same resolved user-document language for each new `Title` value.
9) Add one new log entry in PROGRESS Log:
   - YYYY-MM-DD — Added feature planning tasks TASK-XX~TASK-YY for [feature-slug].
10) Update selected `.ai/features/<filename>` file:
   - `Status: READY_FOR_PLAN` -> `Status: PLANNED`
   - Append a short plan output note including task range (`TASK-XX~TASK-YY`) and date.

Output format at end:
- Feature input source (`.ai/features/<filename>`)
- Feature note added (exact line)
- New task range (TASK-XX~TASK-YY)
- Created task files list
- PROGRESS rows added count
- Feature file status update result
