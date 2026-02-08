---
name: rw-plan-strict
description: "Ralph Strict: add feature notes + create TASK-XX files with archive-safe PROGRESS sync"
agent: agent
argument-hint: "No inline input. Prepare .ai/features/YYYYMMDD-HHMM-<slug>.md with Status: READY_FOR_PLAN."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Append one feature note to `PLAN.md`.
- Create 3-8 new atomic `TASK-XX-*.md` files without renumbering existing tasks.
- Ensure new `pending` rows are visible in active `PROGRESS.md` even when archives exist.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

You are adding a new feature to an existing Ralph-style orchestration workspace.

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

Feature input resolution (required):
1) Read `.ai/features/`.
2) If `.ai/features/` is missing or unreadable, stop immediately and print:
   - first line exactly: `FEATURES_DIR_MISSING`
   - then a short fix guide:
     - run `.github/prompts/rw-feature.prompt.md` first (recommended)
     - create directory `.ai/features/`
     - create one feature file from `.ai/features/FEATURE-TEMPLATE.md`
     - save as `YYYYMMDD-HHMM-<slug>.md`
     - set `Status: READY_FOR_PLAN`
3) Build input-file candidates from `.ai/features/*.md`, excluding:
   - `FEATURE-TEMPLATE.md`
   - `README.md`
4) If no input-file candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_FILE_MISSING`
   - then a short fix guide:
     - run `.github/prompts/rw-feature.prompt.md` to create one READY file (recommended)
     - copy `.ai/features/FEATURE-TEMPLATE.md` to `.ai/features/YYYYMMDD-HHMM-<slug>.md`
     - set `Status: READY_FOR_PLAN`
5) From input-file candidates, select files with exact line: `Status: READY_FOR_PLAN`.
6) If no READY candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_NOT_READY`
   - then a short fix guide:
     - open the latest `YYYYMMDD-HHMM-<slug>.md`
     - change `Status: DRAFT` (or current value) to `Status: READY_FOR_PLAN`
7) If multiple READY candidates exist, resolve selection interactively (single choice):
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
8) If exactly one READY candidate exists, select that file.
9) Expected input filename pattern: `YYYYMMDD-HHMM-<slug>.md`.
10) In any unresolved error case above, stop immediately without additional clarification questions.

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
1) Read `.ai/PLAN.md`, `.ai/PROGRESS.md`, and list existing `.ai/tasks/TASK-*.md` filenames. Open only the needed task files.
2) Resolve feature input using the required precedence rules above.
3) Ask up to 2 short clarification questions only for high-impact ambiguity after feature input is resolved. If details are sufficient, proceed immediately.
4) Build a normalized feature spec (`Goal`, `Constraints`, `Acceptance`) using resolved input + defaults.
5) Append one new Feature Notes line to PLAN.md in this format:
   - YYYY-MM-DD: [feature-slug] Goal/constraints in 1-3 lines. Related tasks: TASK-XX~TASK-YY.
6) Determine next available TASK number from existing task files (max + 1).
7) Create 3~8 new atomic task files for the feature under `.ai/tasks/` as `TASK-XX-<slug>.md`.
   Each file must include:
   - Title
   - Dependencies
   - Description
   - Acceptance Criteria
   - Files to Create/Modify
   - Verification
     - Use project-defined commands (do not hardcode language-specific tools unless the project is explicitly language-specific).
     - Require evidence format: `command`, `exit code`, `key output`.
8) Update `.ai/PROGRESS.md` Task Status table by adding new rows as `pending` with commit `-`.
   - Keep existing rows unchanged.
   - If PROGRESS table is archived/compact, still ensure new pending rows are present in the active Task Status section.
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
