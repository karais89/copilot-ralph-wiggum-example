---
name: rw-init
description: "Scaffold .ai folder: PLAN/tasks/PROGRESS (+ optional GUIDE)"
agent: agent
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Initialize the `.ai` workspace files (`PLAN`, `PROGRESS`, `tasks`, optional `GUIDE`).
- If `.ai` already exists, update append-only sections and add new TASK files only.
- Do not implement product code.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Before any file change, output exactly one line: `LANGUAGE_POLICY_LOADED: <single-line summary>`
4) Do not modify any file before Step 0 completes.

Create (or update without overwriting blindly) this structure:

.ai/
- PLAN.md (concise PRD + Feature Notes append-only)
- PROGRESS.md (task status + log, initialized)
- tasks/ (task files)
- GUIDE.md (optional quickstart)

Steps:
1) Ask me 3 questions about the project goal/scope/constraints.
2) Write PLAN.md (concise PRD) and include `## Feature Notes (append-only)` with one baseline note.
3) Split PLAN.md into 10~20 atomic task files under .ai/tasks/ as TASK-XX-*.md, each with Dependencies/Acceptance Criteria/Files to modify/Verification.
4) Create PROGRESS.md listing all tasks as pending using this minimum structure:
   - `# 진행 현황`
   - `## Task Status`
   - table header: `| Task | Title | Status | Commit |`
   - table separator: `|------|-------|--------|--------|`
   - one row per TASK as `pending` with commit `-`
   - `## Log`
   - one initial log line: `- **YYYY-MM-DD** — Initial tasks created.`
   - Keep machine-parsed tokens (`Task Status`, `Log`, `pending`) exactly as written.
5) If .ai already exists, do not rewrite the whole PLAN; update Feature Notes only and add new TASK-XX files without renumbering existing ones.

Do not implement product code.
