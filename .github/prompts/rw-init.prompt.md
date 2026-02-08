---
name: rw-init
description: "Scaffold .ai folder: PLAN/tasks/PROGRESS (+ optional GUIDE)"
agent: agent
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Initialize the `.ai` workspace files (`PLAN`, `PROGRESS`, `tasks`, optional `GUIDE`).
- If `.ai` already exists, update append-only sections and avoid bulk TASK generation.
- Do not implement product code.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If `.ai/CONTEXT.md` is missing, create it first with a minimal bootstrap language-policy template, then read it.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Bootstrap template for `.ai/CONTEXT.md` (when missing):
- `# 워크스페이스 컨텍스트`
- `## 언어 정책`
  - Prompt body language (`.github/prompts/*.prompt.md`): English (required)
  - User document language (`.ai/*` docs): Korean by default
  - Commit message language: English (Conventional Commits)
- `## 기계 파싱 토큰 (번역 금지)`
  - `Task Status`, `Log`
  - `pending`, `in-progress`, `completed`
  - `LANG_POLICY_MISSING`
- `## 프롬프트 작성 규칙`
  - Every prompt reads `.ai/CONTEXT.md` first via Step 0

Create (or update without overwriting blindly) this structure:

.ai/
- PLAN.md (concise PRD + Feature Notes append-only)
- PROGRESS.md (task status + log, initialized)
- tasks/ (task files)
- GUIDE.md (optional quickstart)

Steps:
1) Infer initialization inputs non-interactively from repository context.
   - Inspect available context sources first (README, package manifest, source layout, existing `.ai/*` files).
   - Infer:
     - Project goal
     - Scope boundaries (in/out)
     - Constraints and verification expectations
   - Do not ask the user questions during rw-init.
2) Resolve inferred values with safe defaults and continue (do not stop):
   - Goal default: `Initialize project orchestration workspace for the current repository.`
   - Scope default: `Focus on the current repository and minimal initial deliverables.`
   - Constraints default: `Backward-compatible changes, minimal scope, and at least one canonical verification command succeeds (exit code 0).`
3) Write PLAN.md (concise PRD) and include `## Feature Notes (append-only)` with one baseline note.
   - In PLAN initial summary/notes, include 1-3 lines of `assumptions/defaults used` when any default above is applied.
   - In the same section, record inferred goal/scope/constraints.
   - In the baseline note under `## Feature Notes (append-only)`, state whether defaults were applied for goal/scope/constraints.
4) Create minimal initialization task files under `.ai/tasks/`:
   - If no `TASK-XX-*.md` exists yet, create exactly 1 bootstrap task:
     - `TASK-01-bootstrap-workspace.md`
   - The task must include:
     - Dependencies
     - Acceptance Criteria
     - Files to modify
     - Verification
   - If task files already exist, do not generate bulk tasks during rw-init.
5) Initialize or update PROGRESS.md using this minimum structure:
   - If `PROGRESS.md` is missing:
     - Create it with:
       - `# 진행 현황`
       - `## Task Status`
       - table header: `| Task | Title | Status | Commit |`
       - table separator: `|------|-------|--------|--------|`
       - one row per current TASK as `pending` with commit `-`
       - `## Log`
       - one initial log line: `- **YYYY-MM-DD** — Initial tasks created.`
   - If `PROGRESS.md` already exists:
     - Keep existing Task Status rows and Log entries unchanged.
     - Add only missing TASK rows as `pending` with commit `-`.
   - Keep machine-parsed tokens (`Task Status`, `Log`, `pending`) exactly as written.
6) If .ai already exists, do not rewrite the whole PLAN; update Feature Notes only.
   - Add new TASK-XX files only when explicitly requested.
   - Never renumber existing TASK files.

Do not implement product code.
