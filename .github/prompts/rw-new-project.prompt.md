---
name: rw-new-project
description: "Integrated new-project bootstrap: scaffold + intent-first discovery + bootstrap feature seed"
agent: agent
argument-hint: "Optional one-line project idea. Example: shared travel itinerary planner."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Use this prompt for new/empty repositories.
- Scope: scaffold + intent discovery + bootstrap feature seed only.
- Task decomposition is not done here; run `rw-plan` next.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If missing, create it from `.ai/templates/CONTEXT-BOOTSTRAP.md` when available; otherwise create a minimal bootstrap context file.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Inputs:
- `projectIdea` (optional)

Constants (do not change during one run):
- `DISCOVERY_MAX_ROUNDS=2`
- `DISCOVERY_MAX_FOLLOWUP_QUESTIONS=3`

Rules:
- Do not edit product code.
- This prompt must run in a top-level Copilot Chat turn.
  - If not top-level, output `TOP_LEVEL_REQUIRED` and stop.
- Interactive fallback must follow `.github/prompts/RW-INTERACTIVE-POLICY.md`.
- Keep machine tokens unchanged (`Task Status`, `Log`, `pending`, `Status`, `READY_FOR_PLAN`, `PLANNED`).
- Write user-facing prose in language resolved from `.ai/CONTEXT.md` (default Korean if ambiguous).
- Do not create or modify `TASK-XX` files in this prompt.
- Do not create git commits in this prompt.
- Idempotency:
  - never renumber existing tasks
  - never rewrite existing history in `PLAN Feature Notes` or `PROGRESS Log`
  - add missing rows/files only

Workflow:
1) Scaffold baseline via shared script (required):
   - Run `scripts/rw-bootstrap-scaffold.sh "<workspace-root-absolute-path>"`.
   - If script is missing or fails, stop immediately and output:
     - first line exactly: `RW_SCAFFOLD_FAILED`
     - second line: `<short reason>`
     - third line: `Fix scaffold script/runtime and rerun rw-new-project.`

2) Resolve direction seed deterministically:
   - `projectIdea` if present
   - else latest meaningful `PLAN` overview
   - else latest `PROJECT-CHARTER` summary
   - else empty

3) Two-step adaptive discovery (intent first, then targeted clarification):
   - Round 1 (intent capture):
     - ensure one clear intent sentence exists.
     - if seed is empty, ask one plain-language question via `#tool:vscode/askQuestions` first:
       - `무엇을 만들고 싶은지 한 문장으로 알려주세요. 기술/설계 용어는 몰라도 됩니다.`
     - if `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
     - if still unresolved after one fallback, stop and output:
       - `PROJECT_IDEA_MISSING`
   - Round 2 (adaptive clarification):
     - infer likely project shape from Round 1 intent.
     - generate only high-impact follow-up questions that reduce implementation risk.
     - ask up to `DISCOVERY_MAX_FOLLOWUP_QUESTIONS` (max 3), and only for unresolved items.
     - use `#tool:vscode/askQuestions` for this round (single grouped interaction preferred).
     - if `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
     - preferred focus areas (pick only what is needed):
       - primary target user/use context
       - first-release scope boundary (must-have vs later)
       - platform/runtime constraints and baseline verification command
     - unanswered items are filled with safe defaults and explicitly recorded in assumptions.
   - Keep user burden low: avoid jargon and avoid asking what can be safely inferred.

4) Update `PLAN.md` overview (concise):
   - keep title unchanged unless missing
   - ensure `## Feature Notes (append-only)` exists
   - write/update 5~10 lines only: purpose, inferred users, MVP scope, inferred constraints, verification baseline (default when missing)

5) Create one project charter note from template:
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

6) Create or reuse bootstrap feature seed:
   - reuse the latest `.ai/features/*.md` containing exact heading `# FEATURE: bootstrap-foundation` when status is `DRAFT` or `READY_FOR_PLAN`
   - else create from `.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md` (fallback to inline equivalent structure)
   - file path pattern: `.ai/features/YYYYMMDD-HHMM-bootstrap-foundation.md`
   - ensure status is `Status: READY_FOR_PLAN`
   - do not change bootstrap feature status to `PLANNED` in this prompt

7) Decide next command:
   - if active `.ai/tasks/TASK-*.md` exists, set `NEXT_COMMAND=rw-run`
   - else set `NEXT_COMMAND=rw-plan`

Output format (machine-friendly, fixed keys):
- `SCAFFOLD_RESULT=<created|updated|skipped>`
- `PLAN_OVERVIEW_RESULT=<created|updated|appended|unchanged>`
- `CHARTER_FILE=<path>`
- `BOOTSTRAP_FEATURE_FILE=<path>`
- `BOOTSTRAP_FEATURE_STATUS=<READY_FOR_PLAN>`
- `BOOTSTRAP_TASKS=<created|skipped>`
- `TASK_RANGE=<TASK-XX~TASK-YY|none>`
- `TASK_COUNT=<n>`
- `DISCOVERY_ROUNDS=<0|1|2>`
- `UNRESOLVED_OPEN_QUESTIONS=<n>`
- `BOOTSTRAP_COMMIT_RESULT=<created|skipped|failed>`
- `BOOTSTRAP_COMMIT_SHA=<sha|none>`
- `NEXT_COMMAND=<rw-plan|rw-run>`

Output defaults for removed responsibilities:
- `BOOTSTRAP_TASKS=skipped`
- `TASK_RANGE=none`
- `TASK_COUNT=0`
- `BOOTSTRAP_COMMIT_RESULT=skipped`
- `BOOTSTRAP_COMMIT_SHA=none`
