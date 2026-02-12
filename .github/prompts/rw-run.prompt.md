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
- Follow `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md` exactly.
- Resolve target metadata via `scripts/rw-resolve-target-root.sh` against workspace root.
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
- On every controlled stop/exit path in this loop, print exactly one machine-readable next step line:
  - `NEXT_COMMAND=<rw-doctor|rw-archive|rw-review|rw-run>`

## Loop
Initialize runtime counters before the first loop iteration:
- `RUNSUBAGENT_DISPATCH_COUNT=0`
- `UNFINISHED_TASK_SEEN=false`

Repeat:
  1) If `TARGET_ROOT/.ai/PAUSE.md` exists:
     - print "⏸️ PAUSE.md detected. Remove it to resume."
     - print `NEXT_COMMAND=rw-archive`
     - stop
  2) If `TARGET_ROOT/.ai/ARCHIVE_LOCK` exists:
     - print "⛔ Archive lock detected (.ai/ARCHIVE_LOCK). Wait for archive completion, then retry."
     - print `NEXT_COMMAND=rw-run`
     - stop
  3) Preflight gate:
     - verify `TARGET_ROOT` is inside a git repository
     - verify `<AI_ROOT>`, `<TASKS>`, and `<PLAN>` are readable
     - if any check fails:
       - print `RW_DOCTOR_BLOCKED`
       - print `Run rw-doctor.prompt.md and fix blockers before rw-run.`
       - print `NEXT_COMMAND=rw-doctor`
       - stop
  4) If <PROGRESS> does not exist, create it by listing all `TASK-*.md` from <TASKS> as `pending`
  5) Scan `TASK-*.md` in <TASKS>; add as `pending` only task IDs that are missing from both:
     - active Task Status table in <PROGRESS>
     - every `<ARCHIVE_DIR>/STATUS-*.md` file (glob)
  6) Read <PROGRESS> to determine whether unfinished tasks remain
     - If any `pending` or `in-progress` row exists, set `UNFINISHED_TASK_SEEN=true`
  7) If completed rows in <PROGRESS> exceed 20 OR total <PROGRESS> size exceeds 8,000 chars OR Log entry count exceeds 40:
     - print "📦 Manual archive required. Create TARGET_ROOT/.ai/PAUSE.md if missing, keep it present, run rw-archive.prompt.md, then resume."
     - print `NEXT_COMMAND=rw-archive`
     - stop
  8) If <PROGRESS> Log contains unresolved `REVIEW-ESCALATE` for one or more tasks:
     - Parse unresolved task IDs where `REVIEW-ESCALATE TASK-XX ...` has no later `REVIEW-ESCALATE-RESOLVED TASK-XX ...`.
     - Let `FIRST_BLOCKED_TASK` be the lexically smallest unresolved task id.
     - Print:
       - `REVIEW_BLOCKED <FIRST_BLOCKED_TASK>`
       - `REVIEW_BLOCKED_TASKS=<comma-separated-task-ids>`
       - `REVIEW_BLOCKED_COUNT=<n>`
       - `NEXT_COMMAND=rw-review`
     - stop
  9) If active Task Status has no `pending`/`in-progress` rows, and every TASK ID from <TASKS> exists in either:
     - active <PROGRESS> Task Status table, or
     - any `<ARCHIVE_DIR>/STATUS-*.md` file (glob),
     then:
       - If `UNFINISHED_TASK_SEEN=true` and `RUNSUBAGENT_DISPATCH_COUNT=0`:
         - print `RW_SUBAGENT_NOT_DISPATCHED`
         - print `NEXT_COMMAND=rw-doctor`
         - stop
       - Append one log line to <PROGRESS>:
         - `- **YYYY-MM-DD** — RUNSUBAGENT_DISPATCH_COUNT: <RUNSUBAGENT_DISPATCH_COUNT>`
       - print `RUNSUBAGENT_DISPATCH_COUNT=<RUNSUBAGENT_DISPATCH_COUNT>`
       - print "✅ All tasks completed."
       - print "Next: run rw-review.prompt.md to review completed tasks."
       - print `NEXT_COMMAND=rw-review`
       - exit
  10) If `#tool:agent/runSubagent` is unavailable:
     - print `runSubagent unavailable`
     - print `RW_ENV_UNSUPPORTED`
     - print "This environment does not support autonomous rw-run. Run rw-doctor.prompt.md and rerun in a runSubagent-supported environment."
     - print `NEXT_COMMAND=rw-doctor`
     - stop
  11) Build one-task dispatch lock and completion baseline:
      - Select exactly one dispatchable task as `LOCKED_TASK_ID` from active `pending`/`in-progress` rows:
        - dependencies satisfied only
        - choose highest-priority candidate
      - If no dispatchable task exists while unfinished rows remain:
        - print `RW_TASK_DEPENDENCY_BLOCKED`
        - print `NEXT_COMMAND=rw-plan`
        - stop
      - Capture `BEFORE_COMPLETED_SET` from active Task Status (`TASK-XX` where status is `completed`).
  12) Call `#tool:agent/runSubagent` with SUBAGENT_PROMPT exactly as provided below, injecting `LOCKED_TASK_ID`
      - Immediately before call, print `RUNSUBAGENT_DISPATCH_BEGIN <LOCKED_TASK_ID>`
  13) Post-dispatch hard validation (mandatory):
      - Re-read <PROGRESS> and capture `AFTER_COMPLETED_SET` from active Task Status.
      - Compute `NEWLY_COMPLETED_TASKS = AFTER_COMPLETED_SET - BEFORE_COMPLETED_SET`.
      - If `|NEWLY_COMPLETED_TASKS| != 1`:
        - print `RW_SUBAGENT_COMPLETION_DELTA_INVALID`
        - print `LOCKED_TASK_ID=<LOCKED_TASK_ID>`
        - print `NEWLY_COMPLETED_TASKS=<comma-separated-task-ids|none>`
        - print `NEXT_COMMAND=rw-run`
        - stop
      - Let `ONLY_COMPLETED` be the single item in `NEWLY_COMPLETED_TASKS`.
      - If `ONLY_COMPLETED != LOCKED_TASK_ID`:
        - print `RW_SUBAGENT_COMPLETED_WRONG_TASK`
        - print `LOCKED_TASK_ID=<LOCKED_TASK_ID>`
        - print `ONLY_COMPLETED=<ONLY_COMPLETED>`
        - print `NEXT_COMMAND=rw-run`
        - stop
      - Increment `RUNSUBAGENT_DISPATCH_COUNT` by 1 and print `RUNSUBAGENT_DISPATCH_OK <LOCKED_TASK_ID>`
  14) Repeat

## Rules
- Invoke runSubagent sequentially (one at a time)
- Choose exactly one dispatchable task per iteration and lock it as `LOCKED_TASK_ID`
- Do not implement code directly; manage the loop only
- Trust <PROGRESS> over any verbal "done" claim from subagents
- Never simulate completion. Do not mark tasks `completed` or write commit hashes unless corresponding real code/test changes were executed under `TARGET_ROOT`.
- Enforce one-dispatch/one-completion invariant: each successful dispatch must add exactly one newly completed task, and it must equal `LOCKED_TASK_ID`.
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
Locked task for this dispatch is `LOCKED_TASK_ID`.

Rules:
- Fully implement only `LOCKED_TASK_ID`.
- Do not choose or complete a different task.
- Read/write only files under `TARGET_ROOT` for this run. Do not touch another workspace-level `.ai`.
- Never call `#tool:agent/runSubagent` from this subagent (nested subagent calls are disallowed).
- Run build/verification commands; if issues are found, fix them all.
- Never fabricate verification output, completion status, or commit evidence.
- Update <PROGRESS> for `LOCKED_TASK_ID` only (status to `completed`, commit message, and a Log entry).
- Do not change status rows for any other task.
- Commit changes with a conventional commit message focused on user impact.
- Exit immediately after implementation and commit.
</SUBAGENT_PROMPT>

BEGIN ORCHESTRATION NOW.
</ORCHESTRATOR_INSTRUCTIONS>
