---
name: rw-init
description: "Scaffold .ai folder: PLAN/tasks/PROGRESS (+ optional GUIDE)"
agent: agent
---

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
4) Create PROGRESS.md listing all tasks as pending.
5) If .ai already exists, do not rewrite the whole PLAN; update Feature Notes only and add new TASK-XX files without renumbering existing ones.

Do not implement product code.
