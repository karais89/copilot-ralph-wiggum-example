---
name: rw-new-project
description: "Integrated new-project bootstrap: scaffolding + discovery + bootstrap feature/task planning in one prompt."
agent: agent
argument-hint: "Optional one-line project idea. Example: shared travel itinerary planner."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Use this prompt when the repository is new/empty and project intent is not yet defined.
- Perform workspace scaffolding (`CONTEXT`, `PLAN`, `PROGRESS`, optional `TASK-01`) and project discovery in one run.
- Create one bootstrap feature and decompose bootstrap foundation tasks (`TASK-02+`) for the agreed project charter.
- Update `PLAN.md` overview and create one discovery note under `.ai/notes/`.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If `.ai/CONTEXT.md` is missing, create it first with a minimal bootstrap language-policy template, then read it.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Bootstrap template for `.ai/CONTEXT.md` (when missing):
- `# Workspace Context`
- `## Language Policy`
  - Prompt body language (`.github/prompts/rw-*.prompt.md`): English (required)
  - User document language (`.ai/*` docs): Korean by default
  - Commit message language: English (Conventional Commits)
- `## Machine-Parsed Tokens (Do Not Translate)`
  - `Task Status`, `Log`
  - `pending`, `in-progress`, `completed`
  - `LANG_POLICY_MISSING`
- `## Prompt Authoring Rules`
  - Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first via Step 0

Project idea input (optional): ${input:projectIdea:Optional one-line project idea. Example: shared travel itinerary planner.}
Non-interactive marker (optional): include literal token `[NON_INTERACTIVE]` in `projectIdea` to force non-interactive bootstrap.

You are initializing a new Ralph orchestration workspace and defining initial project direction.

Target files:
- `.ai/CONTEXT.md` (create only if missing)
- `.ai/PLAN.md` (required)
- `.ai/PROGRESS.md` (required)
- `.tmp/rw-active-target-id.txt` (required, active target id pointer)
- `.tmp/rw-targets/<target-id>.env` (required, target registry entry)
- `.tmp/rw-active-target-root.txt` (required, target root pointer; legacy compatibility)
- `.ai/tasks/TASK-01-bootstrap-workspace.md` (optional, create only when no task files exist)
- `.ai/tasks/TASK-02-*.md` ... (bootstrap foundation tasks, conditional)
- `.ai/features/YYYYMMDD-HHMM-bootstrap-foundation.md` (bootstrap feature, conditional)
- `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` (required, create exactly one)

Rules:
- Do not edit product code.
- This prompt must run in a top-level Copilot Chat turn. If invoked in nested/subagent context, output `TOP_LEVEL_REQUIRED` and stop.
- This prompt may create exactly one bootstrap feature file under `.ai/features/`.
- This prompt may create `TASK-02+` only for bootstrap foundation decomposition.
- Keep existing `PROGRESS` task rows/log entries unchanged on rerun; add only missing task rows.
- Keep `.ai/PLAN.md` concise; do not add full PRD/spec decomposition.
- Keep machine tokens untouched where present (`Task Status`, `Log`, status enums).
- Write user-facing content in language resolved from `.ai/CONTEXT.md` (default Korean if ambiguous).
- Keep task section headers unchanged (`Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Verification`) and write section values/prose in the resolved user-document language.
- Clarification-first: for ambiguous requirements, ask follow-up questions persistently before applying defaults, except in non-interactive mode.
- Non-interactive mode:
  - Enable when either:
    - `projectIdea` contains literal token `[NON_INTERACTIVE]`, or
    - `.tmp/rw-noninteractive.flag` exists.
  - In this mode, never call `#tool:vscode/askQuestions` and never ask interactive follow-up questions.
  - Resolve missing values with safe defaults (`AI_DECIDE` equivalent) and continue.
- Bootstrap task sizing rule:
  - Each task should be independently deliverable in roughly 30~120 minutes.
  - If a task is likely >120 minutes, split it.
  - If a task is likely <30 minutes and not independently valuable, merge it.
  - Each task must include at least one concrete verification command in `Verification`.
- Bootstrap task count rule:
  - Default target: 10~20 tasks.
  - Very small/simple bootstrap scope: 5 tasks allowed.

Workflow:
1) Ensure scaffolding directories exist:
   - `.ai/`, `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`, `.ai/features/`, `.tmp/`, `.tmp/rw-targets/`
   - Set default target id to `workspace-root`.
   - Write current workspace root absolute path to `.tmp/rw-active-target-root.txt` (legacy compatibility; overwrite if exists).
   - Write `workspace-root` to `.tmp/rw-active-target-id.txt` (overwrite if exists).
   - Write `.tmp/rw-targets/workspace-root.env` with:
     - `TARGET_ID=workspace-root`
     - `TARGET_ROOT=<current-workspace-root-absolute-path>`
   - Always keep `.tmp/rw-active-target-root.txt` as a plain absolute path.
2) Bootstrap minimal workspace files:
   - `PLAN.md`:
     - If missing, create:
       - `# <repository-name>`
       - `## Overview`
       - `- Project purpose is undecided (user input required).`
       - `- Technology stack is undecided.`
       - `- Next step: generate bootstrap feature/tasks with this prompt, then run rw-run-lite or rw-run-strict.`
       - `## Feature Notes (append-only)`
     - If exists, keep content and ensure `## Feature Notes (append-only)` section exists.
   - `TASK-01`:
     - If no `TASK-XX-*.md` exists, create `TASK-01-bootstrap-workspace.md` with:
       - Title
       - Dependencies
       - Description
       - Acceptance Criteria
       - Files to Create/Modify
       - Verification
       - Keep the section headers above exactly as written, but write all values/prose in the resolved user-document language.
   - `PROGRESS.md`:
     - If missing, create:
       - `# Progress`
       - `## Task Status`
       - `| Task | Title | Status | Commit |`
       - `|------|-------|--------|--------|`
       - one row per existing task file as `pending` with commit `-`
       - `## Log`
       - `- **YYYY-MM-DD** — Initial workspace scaffolded by rw-new-project.`
     - If exists, keep existing rows/logs and add only missing task rows as `pending`.
     - For newly added rows, write the `Title` value in the same resolved user-document language.
3) Resolve initial direction input:
   - Determine `NON_INTERACTIVE_MODE` first:
     - true if `projectIdea` contains `[NON_INTERACTIVE]` OR `.tmp/rw-noninteractive.flag` exists.
     - if marker token is present in `projectIdea`, remove only that marker token and keep remaining text.
   - If `projectIdea` is present, use it as seed.
   - If `projectIdea` is missing, first try rerun-safe reuse:
     - If `.ai/PLAN.md` already contains meaningful overview lines (not placeholder-only), use the latest overview as seed.
     - Else if `.ai/notes/PROJECT-CHARTER-*.md` exists, use the latest charter summary as seed.
   - If still missing after rerun-safe reuse:
     - If `NON_INTERACTIVE_MODE=true`, use default seed:
       - `A minimal CLI to capture and summarize meeting action items`
     - Else ask one open-ended question using `#tool:vscode/askQuestions`:
       - intent: "What product/project do you want to build first?"
     - If `NON_INTERACTIVE_MODE=false` and `#tool:vscode/askQuestions` is unavailable, ask once in chat.
     - If `NON_INTERACTIVE_MODE=false` and still missing after one interaction, stop immediately and output exactly: `PROJECT_IDEA_MISSING`.
4) Clarification rounds (interactive, persistent):
   - If `NON_INTERACTIVE_MODE=true`, skip interactive rounds and apply defaults (`AI_DECIDE` equivalent).
   - If `NON_INTERACTIVE_MODE=false`, run 3~6 short clarification rounds when ambiguity exists.
   - In each interactive round, ask 1~3 focused questions (single-choice preferred when practical).
   - Resolve all of the following before finalizing (unless user explicitly chooses `AI_DECIDE`):
     - target users
     - core user value/problem
     - MVP in-scope vs out-of-scope
     - constraints/preferences (stack/time/risk)
     - one verification baseline command (if known)
   - Prefer single-choice options where practical; use short open-ended questions only when options are not practical.
   - Do not settle early if ambiguity remains and question budget is still available.
   - Apply defaults only when:
     - user explicitly selects `AI_DECIDE`, or
     - round budget is exhausted.
   - Record every unresolved ambiguity in `## Open Questions` and `## Assumptions and Defaults Used`.
5) Update `.ai/PLAN.md` overview:
   - Keep title line (`# ...`) unchanged unless missing.
   - Replace placeholder-style overview lines when present.
   - If overview already has meaningful content, append a dated direction update block instead of full rewrite.
   - Ensure `## Feature Notes (append-only)` exists and remains unchanged.
   - Keep overview to 5-10 concise lines:
     - project purpose
     - target users
     - MVP scope
     - key constraints
     - verification baseline
6) Create exactly one discovery note file:
   - Path: `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` (local date)
   - If same-day file exists, append `-v2`, `-v3`, ...
   - Required sections:
     - `# Project Charter`
     - `## Summary`
     - `## Target Users`
     - `## Problem and Value`
     - `## MVP In Scope`
     - `## Out of Scope`
     - `## Constraints and Preferences`
     - `## Verification Baseline`
     - `## Open Questions`
     - `## Assumptions and Defaults Used`
     - `## Recommended Next Step`
   - In `Recommended Next Step`, recommend `rw-run-lite` (or `rw-run-strict`) if bootstrap tasks are created; otherwise recommend `rw-feature`.
7) Create bootstrap feature input (conditional):
   - Build candidates from `.ai/features/*.md`, excluding `FEATURE-TEMPLATE.md` and `README.md`.
   - Reuse existing bootstrap feature only when file body contains exact heading line:
     - `# FEATURE: bootstrap-foundation`
   - If multiple files match, select the latest by filename sort.
   - Otherwise create exactly one new file:
     - path: `.ai/features/YYYYMMDD-HHMM-bootstrap-foundation.md`
     - If same timestamp file exists, append `-v2`, `-v3`, ...
     - Required structure:
       - `# FEATURE: bootstrap-foundation`
       - `Status: READY_FOR_PLAN`
       - `## Summary`
       - `## User Value`
       - `## Goal`
       - `## In Scope`
       - `## Out of Scope`
       - `## Functional Requirements`
       - `## Constraints`
       - `## Acceptance`
       - `## Edge Cases and Error Handling`
       - `## Verification Baseline`
       - `## Risks and Open Questions`
       - `## Notes`
   - Content source: use the finalized project charter from Steps 3~6.
8) Bootstrap task decomposition (conditional, no product-code implementation):
   - Decompose only if no `TASK-02+` files currently exist.
   - Determine next task number from existing tasks (`TASK-01` may already exist); start at max+1.
   - Determine bootstrap task count:
     - Use 10~20 by default.
     - Use 5 only when bootstrap scope is clearly very small/simple.
   - Generate atomic tasks as `TASK-XX-<slug>.md` with required sections:
     - Title
     - Dependencies
     - Description
     - Acceptance Criteria
     - Files to Create/Modify
     - Verification
   - Enforce sizing: each task should be approximately 30~120 minutes.
   - Enforce verification: each task includes at least one concrete command in `Verification`.
   - Focus tasks on foundation only (repo setup, architecture skeleton, baseline tests/verification, core guardrails implied by charter).
   - Update `.ai/PLAN.md` `## Feature Notes (append-only)` with one bootstrap line:
     - `YYYY-MM-DD: [bootstrap-foundation] ... Related tasks: TASK-XX~TASK-YY.`
   - Update `.ai/PROGRESS.md` by adding new task rows as `pending` with commit `-` and append one bootstrap planning log line.
   - Update bootstrap feature status:
     - `Status: READY_FOR_PLAN` -> `Status: PLANNED`
     - Append plan output note with task range and date.
   - If `TASK-02+` already exists, skip decomposition and keep existing task history unchanged.
9) Idempotency:
   - Rerunning this prompt must not erase existing history (`PLAN Feature Notes`, `PROGRESS` logs/rows).
   - Apply additive/minimal updates only when files already exist.
   - Never renumber or rewrite existing `TASK-02+` files generated in prior runs.

Output format at end:
- Scaffolding result (`PLAN`/`PROGRESS`/`TASK-01`)
- PLAN overview update result (updated/appended)
- Charter note file path
- Bootstrap feature file path and status
- Bootstrap task generation result (created/skipped)
- Bootstrap task range and count (if created)
- Clarification rounds used count
- Unresolved open questions count
- Recommended next command (`rw-run-lite`/`rw-run-strict` or `rw-feature`)
