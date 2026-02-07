---
name: rw-plan-strict
description: "Ralph Strict: add feature notes + create TASK-XX files with archive-safe PROGRESS sync"
agent: agent
argument-hint: "Optional: one-line feature summary. Leave blank to use latest READY_FOR_PLAN file in .ai/features."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Append one feature note to `PLAN.md`.
- Create 3-8 new atomic `TASK-XX-*.md` files without renumbering existing tasks.
- Ensure new `pending` rows are visible in active `PROGRESS.md` even when archives exist.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Before any file change, output exactly one line: `LANGUAGE_POLICY_LOADED: <single-line summary>`
4) Do not modify any file before Step 0 completes.

Feature summary: ${input:featureSummary:Optional one-line feature summary (example: add export command). Leave blank to use latest READY_FOR_PLAN file in .ai/features.}

You are adding a new feature to an existing Ralph-style orchestration workspace.

Target files:
- .ai/PLAN.md
- .ai/tasks/TASK-XX-*.md
- .ai/PROGRESS.md
- .ai/features/*.md (only selected READY_FOR_PLAN file, status update to PLANNED when file-based input is used)

Rules:
- Do not rewrite the whole PLAN.md.
- Update PLAN.md only in `## Feature Notes (append-only)`.
- Do not renumber or edit existing TASK IDs/files unless explicitly asked.
- Do not implement product code.

Feature input resolution (required):
1) If `featureSummary` is non-empty, use it as the primary feature input.
2) If `featureSummary` is empty, scan `.ai/features/*.md` and select candidates with an explicit line:
   - `Status: READY_FOR_PLAN`
   - If multiple candidates exist, select the lexicographically greatest filename.
   - Expected filename pattern: `YYYYMMDD-HHMM-<slug>.md`.
3) If both are unavailable, stop immediately and output exactly: `FEATURE_INPUT_MISSING`.

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
1) Read `.ai/PLAN.md`, `.ai/PROGRESS.md`, and list existing `.ai/tasks/TASK-*.md` filenames. Open only the needed task files.
2) Resolve feature input using the required precedence rules above.
3) Ask up to 2 short clarification questions only for high-impact ambiguity. If details are sufficient, proceed immediately.
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
8) Update `.ai/PROGRESS.md` Task Status table by adding new rows as `pending` with commit `-`.
   - Keep existing rows unchanged.
   - If PROGRESS table is archived/compact, still ensure new pending rows are present in the active Task Status section.
9) Add one new log entry in PROGRESS Log:
   - YYYY-MM-DD — Added feature planning tasks TASK-XX~TASK-YY for [feature-slug].
10) If feature input came from `.ai/features/<filename>`, update that file:
   - `Status: READY_FOR_PLAN` -> `Status: PLANNED`
   - Append a short plan output note including task range (`TASK-XX~TASK-YY`) and date.

Output format at end:
- Feature input source (`featureSummary` or `.ai/features/<filename>`)
- Feature note added (exact line)
- New task range (TASK-XX~TASK-YY)
- Created task files list
- PROGRESS rows added count
- Feature file status update result (if file-based input was used)
