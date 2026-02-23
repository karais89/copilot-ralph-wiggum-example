---
name: rw-plan
description: "Ralph Plan: append feature note, create TASK-XX files, and sync PROGRESS for one READY feature"
agent: agent
argument-hint: "No inline input. Prepare .ai/features/YYYYMMDD-HHMM-<slug>.md with Status: READY_FOR_PLAN."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Append one feature note to `PLAN.md`.
- Determine `PLAN_MODE=<INITIAL|REPLAN|EXTENSION>` before task generation.
- Generate `PLAN_ID` and plan artifacts under `.ai/plans/<plan_id>/`.
- Create new atomic `TASK-XX-*.md` files without renumbering existing tasks.
- Keep bootstrap coordination context in `.ai/tasks/TASK-00-READBEFORE.md`.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

You are adding a new feature to an existing Ralph orchestration workspace.

Target files:
- `.ai/PLAN.md`
- `.ai/tasks/TASK-00-READBEFORE.md`
- `.ai/tasks/TASK-XX-*.md`
- `.ai/PROGRESS.md`
- `.ai/plans/<plan_id>/research_findings_<slug>.yaml`
- `.ai/plans/<plan_id>/plan-summary.yaml`
- `.ai/runtime/rw-active-plan-id.txt`
- `.ai/features/*.md` (selected READY_FOR_PLAN file, update to `Status: PLANNED`)

Rules:
- Do not rewrite the whole `PLAN.md`.
- Update `PLAN.md` only in `## Feature Notes (append-only)`.
- Do not renumber or edit existing TASK IDs/files unless explicitly asked.
- Do not implement product code.
- Resolve user-document language from `.ai/CONTEXT.md` before writing task/progress prose (default Korean if ambiguous).
- Keep parser tokens and section headers unchanged (`Task Status`, `Log`, `pending`, `Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Test Strategy`, `Verification`).
- Task sizing rule:
  - Each task should be independently deliverable in roughly 30~120 minutes.
  - If likely >120 minutes, split; if <30 minutes and not independently valuable, merge.
- Verification/Test strategy rule:
  - Every task must include `Test Strategy` and `Verification`.
  - `Test Strategy` must include `Unit`, `Integration`, and `Acceptance` entries.
  - `Verification` commands must be prefixed with `[unit]`, `[integration]`, or `[acceptance]`.
  - If behavior changes are introduced, both `[unit]` and `[acceptance]` commands are required.
- Deterministic planning mode:
  - Never call `#tool:vscode/askQuestions` in `rw-plan`.
  - Resolve ambiguity with repository evidence and safe defaults.

Feature input resolution (required):
1) Read `.ai/features/`.
2) If `.ai/features/` is missing/unreadable, stop and print:
   - `FEATURES_DIR_MISSING`
   - short fix guide to create one READY feature file.
3) Build candidates from `.ai/features/*.md`, excluding:
   - `FEATURE-TEMPLATE.md`
   - `README.md`
4) If no candidates, stop and print:
   - `FEATURE_FILE_MISSING`
   - short fix guide.
5) Select files with exact line: `Status: READY_FOR_PLAN`.
6) If no READY file, stop and print:
   - `FEATURE_NOT_READY`
   - short fix guide.
7) If multiple READY files exist:
   - select lexical latest filename.
   - print `FEATURE_MULTI_READY_AUTOSELECTED=<selected-filename>`.
8) Resolve planning profile from selected feature:
   - `Planning Profile: FAST_TEST` -> `FAST_TEST`
   - `Planning Profile: STANDARD` or missing -> `STANDARD`

Workflow:
1) Ensure baseline files exist:
   - create skeleton `.ai/PLAN.md` if missing, with `## Feature Notes (append-only)`
   - create skeleton `.ai/PROGRESS.md` if missing (`Task Status` table + `Log`)
2) Resolve selected feature input file by rules above.
3) Resolve `PLAN_MODE`:
   - `REPLAN` when selected feature contains `Planning Intent: REPLAN` OR `.ai/runtime/rw-plan-replan.flag` exists
   - else `EXTENSION` when active `PROGRESS` already has task rows OR `.ai/progress-archive/STATUS-*.md` exists
   - else `INITIAL`
4) Generate `PLAN_ID=YYYYMMDD-HHMM-<feature-slug>` (local time).
5) Ensure `.ai/plans/<PLAN_ID>/` exists and write `.ai/runtime/rw-active-plan-id.txt`.
6) Write/update research artifact:
   - `.ai/plans/<PLAN_ID>/research_findings_<slug>.yaml`
   - include objective summary, scanned files/modules, estimated coverage (`0-100`), confidence (`HIGH|MEDIUM|LOW`), gaps/open questions.
7) Build normalized feature spec (`Goal`, `Constraints`, `Acceptance`) from input + defaults.
8) Create/update `.ai/tasks/TASK-00-READBEFORE.md`:
   - include feature source, `PLAN_MODE`, `PLAN_ID`
   - include non-negotiable constraints and verification expectations
   - include one-task-per-dispatch coordination note
9) Append one Feature Notes line in `PLAN.md`:
   - `YYYY-MM-DD: [feature-slug] ... Related tasks: TASK-XX~TASK-YY.`
10) Determine next available TASK number from existing task files.
11) Create atomic tasks under `.ai/tasks/`:
   - `FAST_TEST`: 2~3 tasks
   - `STANDARD` default features: 3~7 tasks
   - `STANDARD` bootstrap-foundation: 10~20 tasks (5 allowed only for clearly tiny scope)
   - each task must include:
     - `Title`
     - `Dependencies`
     - `Description`
     - `Acceptance Criteria`
     - `Files to Create/Modify`
     - `Test Strategy`
     - `Verification`
12) Update `.ai/PROGRESS.md` Task Status table:
   - add new rows as `pending` with commit `-`
   - keep existing rows unchanged
13) Append one log line in `PROGRESS`:
   - `YYYY-MM-DD — Added feature planning tasks TASK-XX~TASK-YY for [feature-slug].`
14) Compute planning quality:
   - `PLAN_RISK_LEVEL=<LOW|MEDIUM|HIGH>`
   - `PLAN_CONFIDENCE=<HIGH|MEDIUM|LOW>`
   - `OPEN_QUESTIONS_COUNT=<n>`
15) Write/update `.ai/plans/<PLAN_ID>/plan-summary.yaml`:
   - `plan_id`, `feature_file`, `plan_mode`, `task_range`, `planning_profile`, `risk_level`, `confidence`, `open_questions_count`
16) Update selected feature file:
   - `Status: READY_FOR_PLAN` -> `Status: PLANNED`
   - append short planning output note with task range/date
17) Cleanup:
   - if `.ai/runtime/rw-plan-replan.flag` exists and planning succeeded, delete it.

Output format at end:
- `PLAN_ID=<id>`
- `PLAN_ARTIFACT_DIR=.ai/plans/<plan_id>/`
- `RESEARCH_FINDINGS_FILE=.ai/plans/<plan_id>/research_findings_<slug>.yaml`
- `PLAN_SUMMARY_FILE=.ai/plans/<plan_id>/plan-summary.yaml`
- `PLAN_FEATURE_FILE=<filename>`
- `PLAN_TASK_RANGE=<TASK-XX~TASK-YY>`
- `PLAN_MODE=<INITIAL|REPLAN|EXTENSION>`
- `TASK_BOOTSTRAP_FILE=.ai/tasks/TASK-00-READBEFORE.md`
- `PLAN_RISK_LEVEL=<LOW|MEDIUM|HIGH>`
- `PLAN_CONFIDENCE=<HIGH|MEDIUM|LOW>`
- `OPEN_QUESTIONS_COUNT=<n>`
- `PLANNING_PROFILE_APPLIED=<STANDARD|FAST_TEST>`
- `FEATURE_MULTI_READY_AUTOSELECTED=<filename|none>`
- `NEXT_COMMAND=rw-run`
