---
name: rw-plan-lite
description: "Ralph Lite: add one feature by appending Feature Notes + creating TASK files + syncing PROGRESS"
agent: agent
argument-hint: "No inline input. Prepare .ai/features/YYYYMMDD-HHMM-<slug>.md with Status: READY_FOR_PLAN."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Append one feature note to `PLAN.md`.
- Create 3-6 new atomic `TASK-XX-*.md` files without renumbering existing tasks.
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

Feature input resolution (required):
1) Read `.ai/features/`.
2) If `.ai/features/` is missing or unreadable, stop immediately and print:
   - first line exactly: `FEATURES_DIR_MISSING`
   - then a short fix guide:
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
     - copy `.ai/features/FEATURE-TEMPLATE.md` to `.ai/features/YYYYMMDD-HHMM-<slug>.md`
     - set `Status: READY_FOR_PLAN`
5) From input-file candidates, select files with exact line: `Status: READY_FOR_PLAN`.
6) If no READY candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_NOT_READY`
   - then a short fix guide:
     - open the latest `YYYYMMDD-HHMM-<slug>.md`
     - change `Status: DRAFT` (or current value) to `Status: READY_FOR_PLAN`
7) If multiple READY candidates exist, stop immediately and print:
   - first line exactly: `FEATURE_MULTI_READY`
   - then a short fix guide:
     - keep exactly one file as `Status: READY_FOR_PLAN`
     - set other READY files to `Status: DRAFT` (or `Status: PLANNED` if already consumed)
8) If exactly one READY candidate exists, select that file.
9) Expected input filename pattern: `YYYYMMDD-HHMM-<slug>.md`.
10) In any error case above, stop immediately without clarification questions.

Normalization rules:
1) Backward compatibility: if resolved input already includes structured sections (`goal`, `constraints`, `acceptance`), preserve and use them.
2) If resolved input is a one-line summary, normalize to:
   - Goal: that one-line summary.
   - Constraints (defaults):
     - Keep existing commands/behavior backward-compatible.
     - Minimize scope and file changes to only what is necessary.
     - `npm run build` must pass.
   - Acceptance (defaults):
     - User-facing behavior for the goal is implemented and invokable.
     - Error paths return clear user-friendly messages.
     - `npm run build` passes after changes.

Workflow:
1) Read `.ai/PLAN.md`, `.ai/PROGRESS.md`, and list existing `.ai/tasks/TASK-*.md` filenames.
2) Resolve feature input using the required precedence rules above.
3) Ask up to 2 short clarification questions only for high-impact ambiguity after feature input is resolved. If details are sufficient, proceed immediately.
4) Build a normalized feature spec (`Goal`, `Constraints`, `Acceptance`) using resolved input + defaults.
5) Append one new Feature Notes line to PLAN.md in this format:
   - YYYY-MM-DD: [feature-slug] Goal/constraints in 1-3 lines. Related tasks: TASK-XX~TASK-YY.
6) Determine next available TASK number from existing task files (max + 1).
7) Create 3~6 new atomic task files for the feature under `.ai/tasks/` as `TASK-XX-<slug>.md`.
   Each file must include:
   - Title
   - Dependencies
   - Description
   - Acceptance Criteria
   - Files to Create/Modify
   - Verification
8) Update `.ai/PROGRESS.md` Task Status table by adding only new rows as `pending` with commit `-`.
   Keep existing rows unchanged.
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
