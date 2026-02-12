---
name: rw-new-project
description: "Integrated new-project bootstrap: scaffold + low-friction discovery + bootstrap feature/task planning"
agent: agent
argument-hint: "Optional one-line project idea. Example: shared travel itinerary planner."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Use this prompt for new/empty repositories.
- Keep role boundary: `rw-init` responsibilities are included here, plus low-friction discovery and bootstrap decomposition.
- Use shared scaffold script and templates to minimize ad-hoc branching.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If missing, create it from `.ai/templates/CONTEXT-BOOTSTRAP.md` when available; otherwise create a minimal bootstrap context file.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Inputs:
- `projectIdea` (optional)
- literal marker `[NON_INTERACTIVE]` in `projectIdea` (optional)
- literal marker `[NO_AUTO_COMMIT]` in `projectIdea` (optional)

Constants (do not change during one run):
- `DISCOVERY_MAX_ROUNDS=2`
- `DISCOVERY_MAX_FOLLOWUP_QUESTIONS=3`
- `BOOTSTRAP_DEFAULT_TASK_COUNT=10`
- `BOOTSTRAP_SMALL_SCOPE_TASK_COUNT=5`
- `TASK_SIZE_MIN_MINUTES=30`
- `TASK_SIZE_MAX_MINUTES=120`
- `AUTO_COMMIT_BOOTSTRAP_DEFAULT=true`

Rules:
- Do not edit product code.
- This prompt must run in a top-level Copilot Chat turn.
  - If not top-level, output `TOP_LEVEL_REQUIRED` and stop.
- Interactive fallback must follow `.github/prompts/RW-INTERACTIVE-POLICY.md`.
- Keep machine tokens unchanged (`Task Status`, `Log`, `pending`, `Status`, `READY_FOR_PLAN`, `PLANNED`).
- Keep task section headers unchanged (`Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Verification`).
- Write user-facing prose in language resolved from `.ai/CONTEXT.md` (default Korean if ambiguous).
- Keep bootstrap decomposition compact in `rw-new-project`; additional decomposition belongs to `rw-plan`.
- Task policy:
  - size target: 30~120 minutes per task
  - if likely >120 minutes split, if <30 minutes and not independently valuable merge
  - each task must include at least one concrete verification command
- Idempotency:
  - never renumber existing tasks
  - never rewrite existing history in `PLAN Feature Notes` or `PROGRESS Log`
  - add missing rows/files only

Workflow:
1) Scaffold baseline via shared script:
   - Preferred: run `scripts/rw-bootstrap-scaffold.sh "<workspace-root-absolute-path>"`.
   - If script is unavailable, perform equivalent minimal scaffold manually:
     - ensure `.ai/`, `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`, `.ai/features/`, `.ai/runtime/`, `.ai/runtime/rw-targets/`.
     - ensure pointer trio exists and is synchronized:
       - `.ai/runtime/rw-active-target-id.txt`
       - `.ai/runtime/rw-targets/workspace-root.env`
       - `.ai/runtime/rw-active-target-root.txt`
     - create `PLAN.md`, `PROGRESS.md`, and optional `TASK-01-bootstrap-workspace.md` only when missing.

2) Resolve `NON_INTERACTIVE_MODE`:
   - true if `projectIdea` contains `[NON_INTERACTIVE]` OR `.ai/runtime/rw-noninteractive.flag` exists.
   - remove marker token from `projectIdea` if present.
   - resolve `AUTO_COMMIT_BOOTSTRAP`:
     - default: `AUTO_COMMIT_BOOTSTRAP_DEFAULT` (`true`)
     - set `false` if `projectIdea` contains `[NO_AUTO_COMMIT]` OR `.ai/runtime/rw-no-autocommit.flag` exists
     - remove `[NO_AUTO_COMMIT]` marker token from `projectIdea` if present

3) Resolve direction seed deterministically:
   - `projectIdea` (cleaned) if present
   - else latest meaningful `PLAN` overview
   - else latest `PROJECT-CHARTER` summary
   - else default seed: `A minimal CLI to capture and summarize meeting action items`

4) Two-step adaptive discovery (intent first, then targeted clarification):
   - If `NON_INTERACTIVE_MODE=true`, skip questions and apply defaults.
   - If `NON_INTERACTIVE_MODE=false`:
     - Round 1 (intent capture):
       - ensure one clear intent sentence exists.
       - if cleaned `projectIdea` is empty, ask one plain-language question first:
         - `무엇을 만들고 싶은지 한 문장으로 알려주세요. 기술/설계 용어는 몰라도 됩니다.`
       - if still unresolved after one fallback, stop and output:
         - `PROJECT_IDEA_MISSING`
     - Round 2 (adaptive clarification):
       - infer likely project shape from Round 1 intent.
       - generate only high-impact follow-up questions that reduce implementation risk.
       - ask up to `DISCOVERY_MAX_FOLLOWUP_QUESTIONS` (max 3), and only for unresolved items.
       - do not ask fixed/generic questionnaires.
       - preferred focus areas (pick only what is needed):
         - primary target user/use context
         - first-release scope boundary (must-have vs later)
         - platform/runtime constraints and baseline verification command
       - unanswered items are filled with safe defaults and explicitly recorded in assumptions.
   - Keep user burden low: avoid jargon and avoid asking what can be safely inferred.

5) Update `PLAN.md` overview (concise):
   - keep title unchanged unless missing
   - ensure `## Feature Notes (append-only)` exists
   - write/update 5~10 lines only: purpose, inferred users, MVP scope, inferred constraints, verification baseline (default when missing)

6) Create one project charter note from template:
   - use `.ai/templates/PROJECT-CHARTER-TEMPLATE.md` when available
   - output path: `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` (or `-v2`, `-v3`, ...)
   - include sections:
     - Summary
     - Target Users
     - Problem and Value
     - MVP In Scope
     - Out of Scope
     - Constraints and Preferences
     - Verification Baseline
     - Open Questions
     - Assumptions and Defaults Used
     - Recommended Next Step

7) Create or reuse bootstrap feature input:
   - reuse the latest `.ai/features/*.md` containing exact heading `# FEATURE: bootstrap-foundation`
   - else create from `.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md` (fallback to inline equivalent structure)
   - file path pattern: `.ai/features/YYYYMMDD-HHMM-bootstrap-foundation.md`
   - ensure status is `Status: READY_FOR_PLAN`

8) Bootstrap task decomposition (no product code implementation):
   - run only when no `TASK-02+` files exist
   - determine task count deterministically:
     - use `BOOTSTRAP_SMALL_SCOPE_TASK_COUNT` (5) only for clearly small/simple scope
     - otherwise use `BOOTSTRAP_DEFAULT_TASK_COUNT` (10)
   - create `TASK-XX-<slug>.md` files with required sections
   - update:
     - `PLAN.md` `Feature Notes` append one bootstrap line with task range
     - `PROGRESS.md` add pending rows and one bootstrap planning log entry
   - update bootstrap feature status:
     - `Status: READY_FOR_PLAN` -> `Status: PLANNED`
     - append short plan output note with task range/date
   - if `TASK-02+` already exists, skip decomposition

9) Bootstrap commit (default enabled):
   - If `AUTO_COMMIT_BOOTSTRAP=false`, skip commit and set:
     - `BOOTSTRAP_COMMIT_RESULT=skipped`
     - `BOOTSTRAP_COMMIT_SHA=none`
   - Else if workspace is not a git repository, skip commit and set:
     - `BOOTSTRAP_COMMIT_RESULT=skipped`
     - `BOOTSTRAP_COMMIT_SHA=none`
   - Else stage only rw-new-project artifacts under `.ai`:
     - `.ai/PLAN.md`
     - `.ai/PROGRESS.md`
     - `.ai/features/*.md`
     - `.ai/tasks/TASK-*.md`
     - `.ai/notes/PROJECT-CHARTER-*.md`
     - `.ai/runtime/rw-active-target-id.txt`
     - `.ai/runtime/rw-active-target-root.txt`
     - `.ai/runtime/rw-targets/workspace-root.env`
   - If there is nothing staged after this filter:
     - `BOOTSTRAP_COMMIT_RESULT=skipped`
     - `BOOTSTRAP_COMMIT_SHA=none`
   - Otherwise create one commit:
     - message: `chore(rw): bootstrap workspace via rw-new-project`
     - on success:
       - `BOOTSTRAP_COMMIT_RESULT=created`
       - `BOOTSTRAP_COMMIT_SHA=<new-commit-sha>`
     - on failure:
       - `BOOTSTRAP_COMMIT_RESULT=failed`
       - `BOOTSTRAP_COMMIT_SHA=none`

10) Recommended next command:
   - `rw-run` when bootstrap tasks are created or pending (`rw-run` auto-runs doctor preflight when needed)
   - otherwise `rw-feature`

Output format (machine-friendly, fixed keys):
- `SCAFFOLD_RESULT=<created|updated|skipped>`
- `PLAN_OVERVIEW_RESULT=<created|updated|appended|unchanged>`
- `CHARTER_FILE=<path>`
- `BOOTSTRAP_FEATURE_FILE=<path>`
- `BOOTSTRAP_FEATURE_STATUS=<READY_FOR_PLAN|PLANNED>`
- `BOOTSTRAP_TASKS=<created|skipped>`
- `TASK_RANGE=<TASK-XX~TASK-YY|none>`
- `TASK_COUNT=<n>`
- `DISCOVERY_ROUNDS=<0|1|2>`
- `UNRESOLVED_OPEN_QUESTIONS=<n>`
- `BOOTSTRAP_COMMIT_RESULT=<created|skipped|failed>`
- `BOOTSTRAP_COMMIT_SHA=<sha|none>`
- `NEXT_COMMAND=<rw-run|rw-feature>`
