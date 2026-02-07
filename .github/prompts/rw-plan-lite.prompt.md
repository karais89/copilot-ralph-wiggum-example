---
name: rw-plan-lite
description: "Ralph Lite: add one feature by appending Feature Notes + creating TASK files + syncing PROGRESS"
agent: agent
argument-hint: "Required: feature summary (goal, constraints, acceptance)."
---

Feature summary: ${input:featureSummary:goal/constraints/acceptance}

You are adding one feature to an existing Ralph Lite orchestration workspace.

Target files:
- .ai/PLAN.md
- .ai/tasks/TASK-XX-*.md
- .ai/PROGRESS.md

Rules:
- Do not rewrite the whole PLAN.md.
- Update PLAN.md only in `## Feature Notes (append-only)`.
- Do not renumber or edit existing TASK IDs/files unless explicitly asked.
- Do not implement product code.

Workflow:
1) Read `.ai/PLAN.md`, `.ai/PROGRESS.md`, and list existing `.ai/tasks/TASK-*.md` filenames.
2) Ask up to 3 short clarification questions only if needed. If details are sufficient, proceed immediately.
3) Append one new Feature Notes line to PLAN.md in this format:
   - YYYY-MM-DD: [feature-slug] Goal/constraints in 1-3 lines. Related tasks: TASK-XX~TASK-YY.
4) Determine next available TASK number from existing task files (max + 1).
5) Create 3~6 new atomic task files for the feature under `.ai/tasks/` as `TASK-XX-<slug>.md`.
   Each file must include:
   - Title
   - Dependencies
   - Description
   - Acceptance Criteria
   - Files to Create/Modify
   - Verification
6) Update `.ai/PROGRESS.md` Task Status table by adding only new rows as `pending` with commit `-`.
   Keep existing rows unchanged.
7) Add one new log entry in PROGRESS Log:
   - YYYY-MM-DD — Added feature planning tasks TASK-XX~TASK-YY for [feature-slug].

Output format at end:
- Feature note added (exact line)
- New task range (TASK-XX~TASK-YY)
- Created task files list
- PROGRESS rows added count
