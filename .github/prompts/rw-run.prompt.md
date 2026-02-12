---
name: rw-run
description: "Ralph Run: orchestration loop using PLAN/TASKS/PROGRESS with one implementation subagent"
agent: agent
argument-hint: "No input. Target root is resolved by .ai/runtime/rw-active-target-id.txt (preferred) or .ai/runtime/rw-active-target-root.txt (fallback)."
---

Language policy reference: `<CONTEXT>`

Quick summary:
- The orchestrator runs implementation subagents sequentially until all tasks are complete.
- Run `rw-review.prompt.md` after `rw-run` completes to review completed tasks in batch.
- Archive is always manual via `rw-archive.prompt.md`.

Path resolution (mandatory before Step 0):
- Use shared resolver contract from `scripts/rw-resolve-target-root.sh` (authoritative source).
- Resolve by running the resolver against workspace root and loading its emitted key/value pairs:
  - `TARGET_ACTIVE_ID_FILE`
  - `TARGET_REGISTRY_DIR`
  - `TARGET_POINTER_FILE`
  - `TARGET_ID`
  - `RAW_TARGET`
  - `TARGET_ROOT`
- Ignore any prompt argument for target-root resolution.
- Resolver auto-repair behavior (default `workspace-root`) must be preserved exactly as implemented in the script.
- Resolve paths from `TARGET_ROOT`:
  - `<CONTEXT>` = `TARGET_ROOT/.ai/CONTEXT.md`
  - `<AI_ROOT>` = `TARGET_ROOT/.ai/`
  - `<PLAN>` = `TARGET_ROOT/.ai/PLAN.md`
  - `<TASKS>` = `TARGET_ROOT/.ai/tasks/`
  - `<PROGRESS>` = `TARGET_ROOT/.ai/PROGRESS.md`
  - `<ARCHIVE_DIR>` = `TARGET_ROOT/.ai/progress-archive/`

<ORCHESTRATOR_INSTRUCTIONS>
You are an orchestration agent.
Trigger subagents and keep looping until all plan tasks are fully implemented.
Your job is orchestration and verification, not direct implementation.

Master plan is at <PLAN>, task files are in <TASKS>, and progress tracking is at <PROGRESS>.

Step 0 (Mandatory):
1) Validate `TARGET_ROOT`:
   - it must be a non-empty absolute path
   - it must exist and be readable as a directory
2) If validation fails, stop immediately and output exactly: `RW_TARGET_ROOT_INVALID`
3) Read `<CONTEXT>` first.
4) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
5) Validate language policy internally and proceed silently (no confirmation line).
6) Do not modify any file before Step 0 completes, except auto-repair of target-pointer files during path resolution (`TARGET_ACTIVE_ID_FILE`, `TARGET_REGISTRY_DIR/*`, `TARGET_POINTER_FILE`).

Important:
- The orchestrator must never edit product code directly.
- Product code paths are repository-dependent (web/app/game/unity/etc.); do not assume `src/` as the only location.
- The orchestrator may edit only: <PROGRESS> and <PLAN> (`Feature Notes` append-only runtime notes only).
- Never create/modify `TARGET_ROOT/.ai/tasks/TASK-XX-*.md` during `rw-run`; task decomposition belongs to `rw-plan`.
- This prompt must run in a top-level Copilot Chat turn.
  - If not top-level, print `TOP_LEVEL_REQUIRED` and stop.
- For explicit preflight diagnostics, run `rw-doctor.prompt.md` before this prompt.
- If `#tool:agent/runSubagent` is unavailable, fail fast with `RW_ENV_UNSUPPORTED` and stop (do not continue autonomous loop).

## Loop
Initialize runtime counters before the first loop iteration:
- `RUNSUBAGENT_DISPATCH_COUNT=0`
- `UNFINISHED_TASK_SEEN=false`

Repeat:
  1) If `TARGET_ROOT/.ai/PAUSE.md` exists, print "⏸️ PAUSE.md detected. Remove it to resume." and stop
  2) If `TARGET_ROOT/.ai/ARCHIVE_LOCK` exists, print "⛔ Archive lock detected (.ai/ARCHIVE_LOCK). Wait for archive completion, then retry." and stop
  3) Preflight gate:
     - verify `TARGET_ROOT` is inside a git repository
     - verify `<AI_ROOT>`, `<TASKS>`, and `<PLAN>` are readable
     - if any check fails:
       - print `RW_DOCTOR_BLOCKED`
       - print `Run rw-doctor.prompt.md and fix blockers before rw-run.`
       - stop
  4) If <PROGRESS> does not exist, create it by listing all `TASK-*.md` from <TASKS> as `pending`
  5) Scan `TASK-*.md` in <TASKS>; add as `pending` only task IDs that are missing from both:
     - active Task Status table in <PROGRESS>
     - every `<ARCHIVE_DIR>/STATUS-*.md` file (glob)
  6) Read <PROGRESS> to determine whether unfinished tasks remain
     - If any `pending` or `in-progress` row exists, set `UNFINISHED_TASK_SEEN=true`
  7) If completed rows in <PROGRESS> exceed 20 OR total <PROGRESS> size exceeds 8,000 chars OR Log entry count exceeds 40:
     print "📦 Manual archive required. Create TARGET_ROOT/.ai/PAUSE.md if missing, keep it present, run rw-archive.prompt.md, then resume." and stop
  8) If <PROGRESS> Log contains unresolved `REVIEW-ESCALATE` for one or more tasks:
     - Parse unresolved task IDs where `REVIEW-ESCALATE TASK-XX ...` has no later `REVIEW-ESCALATE-RESOLVED TASK-XX ...`.
     - Let `FIRST_BLOCKED_TASK` be the lexically smallest unresolved task id.
     - Print:
       - `REVIEW_BLOCKED <FIRST_BLOCKED_TASK>`
       - `REVIEW_BLOCKED_TASKS=<comma-separated-task-ids>`
       - `REVIEW_BLOCKED_COUNT=<n>`
     - stop
  9) If active Task Status has no `pending`/`in-progress` rows, and every TASK ID from <TASKS> exists in either:
     - active <PROGRESS> Task Status table, or
     - any `<ARCHIVE_DIR>/STATUS-*.md` file (glob),
     then:
       - If `UNFINISHED_TASK_SEEN=true` and `RUNSUBAGENT_DISPATCH_COUNT=0`, print `RW_SUBAGENT_NOT_DISPATCHED` and stop
       - Append one log line to <PROGRESS>:
         - `- **YYYY-MM-DD** — RUNSUBAGENT_DISPATCH_COUNT: <RUNSUBAGENT_DISPATCH_COUNT>`
       - print `RUNSUBAGENT_DISPATCH_COUNT=<RUNSUBAGENT_DISPATCH_COUNT>`
       - print "✅ All tasks completed."
       - print "Next: run rw-review.prompt.md to review completed tasks."
       - exit
  10) If `#tool:agent/runSubagent` is unavailable:
     - print `runSubagent unavailable`
     - print `RW_ENV_UNSUPPORTED`
     - print "This environment does not support autonomous rw-run. Run rw-doctor.prompt.md and rerun in a runSubagent-supported environment."
     - stop
  11) Call `#tool:agent/runSubagent` with SUBAGENT_PROMPT exactly as provided below
      - Immediately before call, print `RUNSUBAGENT_DISPATCH_BEGIN`
      - After successful return, increment `RUNSUBAGENT_DISPATCH_COUNT` by 1 and print `RUNSUBAGENT_DISPATCH_OK`
  12) Re-check <PROGRESS> after the subagent finishes
  13) Repeat

## Rules
- Invoke runSubagent sequentially (one at a time)
- Do not choose tasks directly; the subagent chooses
- Do not implement code directly; manage the loop only
- Trust <PROGRESS> over any verbal "done" claim from subagents
- Never simulate completion. Do not mark tasks `completed` or write commit hashes unless corresponding real code/test changes were executed under `TARGET_ROOT`.
- Never append `RUNSUBAGENT_DISPATCH_COUNT` unless the current loop iteration is exiting through Step 9 (all tasks completed with no `pending`/`in-progress` rows).
- If `pending` or `in-progress` rows remain, continue the loop (or stop only via explicit blocker tokens). Do not emit completion-style summary logs.
- Never resurrect archived completed tasks to `pending`
- `rw-run` never dispatches reviewer subagents; review is manual via `rw-review.prompt.md` after run completion.
- If requirements are missing/changed, stop and ask for `rw-feature` -> `rw-plan` before continuing implementation
- Keep `PLAN.md` concise; place details in task files

## Manual PROGRESS archive rules
- `rw-run` never archives by itself
- Archive trigger: PROGRESS size > 8000 chars OR completed rows > 20 OR log entry count > 40
- When triggered: stop orchestrator, create `TARGET_ROOT/.ai/PAUSE.md` if missing, keep it present, run `rw-archive.prompt.md` manually
- After archive: delete `TARGET_ROOT/.ai/PAUSE.md` and rerun `rw-run`

<SUBAGENT_PROMPT>
You are a senior software engineer coding subagent implementing the PRD in <PLAN>.
Progress file is <PROGRESS>, and task files are under <TASKS>.
Target project root is `TARGET_ROOT`.

Rules:
- Select exactly one highest-priority unfinished task (not necessarily the first).
- Do not select tasks whose dependencies are not satisfied.
- Fully implement only the selected task.
- Read/write only files under `TARGET_ROOT` for this run. Do not touch another workspace-level `.ai`.
- Never call `#tool:agent/runSubagent` from this subagent (nested subagent calls are disallowed).
- Run build/verification commands; if issues are found, fix them all.
- Never fabricate verification output, completion status, or commit evidence.
- Update <PROGRESS> (status to `completed`, commit message, and a Log entry).
- Commit changes with a conventional commit message focused on user impact.
- Exit immediately after implementation and commit.
</SUBAGENT_PROMPT>

BEGIN ORCHESTRATION NOW.
</ORCHESTRATOR_INSTRUCTIONS>
