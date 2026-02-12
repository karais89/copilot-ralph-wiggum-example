---
name: rw-init
description: "Scaffold .ai workspace only: CONTEXT/PLAN/PROGRESS and optional TASK-01 bootstrap"
agent: agent
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Initialize `.ai` workspace scaffolding only.
- Create minimal `PLAN.md` and `PROGRESS.md` skeletons when missing.
- Create at most one bootstrap task (`TASK-01-bootstrap-workspace.md`) only when no task files exist.
- If repository context is empty/template-only, do not infer project purpose/scope/requirements.
- For new project kickoff with discovery, prefer `rw-new-project`.
- Do not implement product code.

Responsibility boundary:
| Stage | Responsibility |
|---|---|
| `rw-init` | Workspace scaffolding only (`CONTEXT`, minimal `PLAN`/`PROGRESS`, optional `TASK-01`) |
| `rw-new-project` | Integrated new-project bootstrap (`rw-init` scaffolding + discovery + bootstrap feature/task decomposition) |
| `rw-doctor` | Preflight environment check before autonomous runs (`top-level`, `runSubagent`, `git`, `.ai` readiness) |
| `rw-feature` | Feature definition (`.ai/features/*.md`) |
| `rw-plan` | Feature-to-task decomposition (`TASK-XX`, `PLAN Feature Notes`, `PROGRESS` sync) |
| `rw-run-*` | Task implementation in product code |

Critical constraints (never override):
- Do not infer arbitrary feature scope. General feature definition/decomposition belongs to `rw-feature` and `rw-plan` (bootstrap foundation is handled in `rw-new-project`).
- If repository context is insufficient, skip purpose/stack/validation inference and write explicit placeholders instead.
- Never create more than one task file during `rw-init`.
- Never create `TASK-02` or higher during `rw-init`.
- Never rewrite existing `PLAN.md` or `PROGRESS.md` contents wholesale.
- Resolve user-document language from `.ai/CONTEXT.md` before writing user-facing prose (default Korean if ambiguous).
- Keep machine/parser tokens and section headers unchanged (`Task Status`, `Log`, `pending`, `Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Verification`).
- In `.ai/tasks/*.md` and PROGRESS `Title` cells, write human-readable values in the resolved user-document language.

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

Create (or update without overwriting blindly) this structure:

.ai/
- CONTEXT.md (language policy + parser-safe tokens)
- PLAN.md (workspace metadata skeleton + Feature Notes append-only)
- PROGRESS.md (Task Status + Log skeleton)
- tasks/ (task files)
- GUIDE.md (optional quickstart)
- runtime/
  - rw-active-target-id.txt (active target id pointer)
  - rw-targets/<target-id>.env (target registry entry; includes TARGET_ROOT)
  - rw-active-target-root.txt (target root pointer)

Steps:
1) Resolve repository context readiness non-interactively.
   - Inspect available context sources first (README, package manifest, source layout, existing `.ai/*` files).
   - Determine context mode:
     - `CONTEXT_READY`: at least one strong project signal exists (meaningful README, non-empty manifest description, or product source files).
     - `CONTEXT_EMPTY`: template-only/empty repository with no strong project signal.
   - Do not ask the user questions during rw-init.
2) If `CONTEXT_READY`, infer minimal metadata only:
   - Project name
   - Short project purpose summary (1-3 lines)
   - Primary tech stack keywords
   - One canonical validation command when discoverable
   - Do not infer features, detailed product requirements, or functional scope.
3) If `CONTEXT_EMPTY`, do not infer project metadata:
   - Project name: use repository directory name.
   - PLAN overview lines (localized to the resolved user-document language; Korean by default):
     - `- Project purpose is undecided (user input required).`
     - `- Technology stack is undecided.`
     - `- Next step: run rw-new-project to finalize direction/bootstrap tasks, then run rw-run-lite or rw-run-strict.`
4) Ensure scaffolding directories exist:
   - `.ai/`, `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`, `.ai/runtime/`, `.ai/runtime/rw-targets/`
   - Set default target id to `workspace-root`.
   - Write current workspace root absolute path to `.ai/runtime/rw-active-target-root.txt` (legacy compatibility; overwrite if exists).
   - Write `workspace-root` to `.ai/runtime/rw-active-target-id.txt` (overwrite if exists).
   - Write `.ai/runtime/rw-targets/workspace-root.env` with:
     - `TARGET_ID=workspace-root`
     - `TARGET_ROOT=<current-workspace-root-absolute-path>`
   - Always keep `.ai/runtime/rw-active-target-root.txt` as a plain absolute path.
5) Create or update `PLAN.md` with strict boundaries:
   - If `PLAN.md` is missing, create exactly:
     - `# <project-name>`
     - `## Overview`
     - If `CONTEXT_READY`: 1-3 summary lines from Step 2 (purpose + stack + validation command)
     - If `CONTEXT_EMPTY`: 1-3 placeholder lines from Step 3
     - `## Feature Notes (append-only)` (empty section, no baseline note)
   - If `PLAN.md` exists:
     - Keep all existing content unchanged.
     - If `## Feature Notes (append-only)` is missing, append the empty section at the end.
   - Forbidden in rw-init PLAN content:
     - Detailed functional requirements
     - Data model/schema design
     - Command/API endpoint lists
     - Task decomposition notes
6) Create minimal initialization task files under `.ai/tasks/`:
   - If no `TASK-XX-*.md` exists yet, create exactly 1 bootstrap task file:
     - `TASK-01-bootstrap-workspace.md`
   - The task must include:
     - Title
     - Dependencies
     - Description
     - Acceptance Criteria
     - Files to Create/Modify
     - Verification
   - Keep the section headers above exactly as written, but write each section value/prose in the resolved user-document language.
   - If task files already exist, do not generate new task files during rw-init.
   - Do NOT create `TASK-02`, `TASK-03`, etc.
7) Initialize or update PROGRESS.md using this minimum structure:
   - If `PROGRESS.md` is missing:
     - Create it with:
       - `# Progress`
       - `## Task Status`
       - table header: `| Task | Title | Status | Commit |`
       - table separator: `|------|-------|--------|--------|`
       - one row per currently existing task file as `pending` with commit `-`
       - `## Log`
       - one initial log line: `- **YYYY-MM-DD** — Initial workspace scaffolded.`
   - If `PROGRESS.md` already exists:
     - Keep existing Task Status rows and Log entries unchanged.
     - Add only missing TASK rows as `pending` with commit `-`.
     - Use the same resolved user-document language for each newly added `Title` value.
   - Keep machine-parsed tokens (`Task Status`, `Log`, `pending`) exactly as written.
8) Idempotency rules:
   - Rerunning rw-init must not erase existing task history or logs.
   - If `.ai` already exists and required skeleton elements are present, perform no-op or minimal additive fixes only.
   - Never renumber existing TASK files.

Do not implement product code.
