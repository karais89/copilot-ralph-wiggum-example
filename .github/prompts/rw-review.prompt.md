---
name: rw-review
description: "Manual reviewer: subagent-backed batch validation for completed tasks with REVIEW_OK/REVIEW_FAIL/REVIEW-ESCALATE updates"
agent: agent
argument-hint: "No input. Target root is resolved by .ai/runtime/rw-active-target-id.txt (preferred) or .ai/runtime/rw-active-target-root.txt (fallback)."
---

Language policy reference: `<CONTEXT>`

Quick summary:
- Run this manually after `rw-run` to review completed tasks in batch.
- Dispatch review subagents per task (default sequential; parallel only when explicitly marked safe).
- Write review outcomes to `PROGRESS` using `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`.
- Emit one normalized review status token: `REVIEW_STATUS=<APPROVED|NEEDS_REVISION|FAILED>`.
- Emit structured issue counters: `REVIEW_ISSUE_COUNT`, `REVIEW_P0_COUNT`, `REVIEW_P1_COUNT`.
- Emit structured findings with severity/file/line fields.
- Write one phase completion note to `.ai/notes/` with standardized cycle-result fields.

Path resolution (mandatory before Step 0):
- Follow `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md` exactly.
- Resolve target metadata via `scripts/rw-resolve-target-root.sh` against workspace root.
- Resolve paths from `TARGET_ROOT`:
  - `<CONTEXT>` = `TARGET_ROOT/.ai/CONTEXT.md`
  - `<PLAN>` = `TARGET_ROOT/.ai/PLAN.md`
  - `<TASKS>` = `TARGET_ROOT/.ai/tasks/`
  - `<PROGRESS>` = `TARGET_ROOT/.ai/PROGRESS.md`
  - `<NOTES>` = `TARGET_ROOT/.ai/notes/`

Step 0 (Mandatory):
1) Validate `TARGET_ROOT`:
   - it must be a non-empty absolute path
   - it must exist and be readable as a directory
2) If validation fails, stop immediately and output exactly: `RW_TARGET_ROOT_INVALID`
3) Read `<CONTEXT>` first.
4) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
5) Validate language policy internally and proceed silently (no confirmation line).
6) Do not modify any file before Step 0 completes, except auto-repair of target-pointer files during path resolution (`TARGET_ACTIVE_ID_FILE`, `TARGET_REGISTRY_DIR/*`, `TARGET_POINTER_FILE`).

Rules:
- This prompt must run in a top-level Copilot Chat turn.
  - If not top-level, print `TOP_LEVEL_REQUIRED` and stop.
- Do not modify product code.
- Only update review-related state in `<PROGRESS>` and one review completion note in `<NOTES>`:
  - `REVIEW_OK TASK-XX: verification passed`
  - `REVIEW_FAIL TASK-XX (n/3): <root-cause>`
  - `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required`
  - `REVIEW-ESCALATE-RESOLVED TASK-XX: <resolution>` (manual recovery path, user-driven)
  - `REVIEW-PHASE-COMPLETE-YYYYMMDD-HHMM.md` (or `-v2`, `-v3`, ...)
- Never fabricate review results.
- Review all currently `completed` tasks in active Task Status.
- This prompt must dispatch `#tool:agent/runSubagent` for per-task validation.
- Subagents must not modify repository files; orchestrator writes `<PROGRESS>` only after collecting results.
- Each review candidate task must be dispatched exactly once in the current review run.
- On every stop path, print exactly one machine-readable next step line:
  - `NEXT_COMMAND=<rw-run|rw-archive>`
- Parallel dispatch policy (deterministic):
  - Default mode is `SEQUENTIAL`.
  - Enable `PARALLEL` only when every review candidate task file contains exact line: `Review Parallel: SAFE`.
  - If enabled, fixed batch size is 2.
  - If any candidate is missing that exact line, use `SEQUENTIAL`.

Procedure:
1) Read `<PROGRESS>` and collect all `completed` tasks in active `Task Status`.
2) If no completed task exists:
   - print `REVIEW_TARGET_MISSING`
   - print `REVIEW_STATUS=FAILED`
   - print `REVIEW_ISSUE_COUNT=0`
   - print `REVIEW_P0_COUNT=0`
   - print `REVIEW_P1_COUNT=0`
   - print `REVIEW_PHASE_NOTE_FILE=none`
   - print `NEXT_COMMAND=rw-run`
   - stop.
3) Build review candidates:
   - For each completed task (`TASK-XX`), locate its latest completion log (`TASK-XX completed`).
   - If there is already a later review log for the same task (`REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`), skip it as already reviewed.
   - Remaining tasks are the review candidate set.
4) If candidate set is empty:
   - print `REVIEW_NOTHING_TO_DO`
   - print `REVIEW_SUMMARY total=0 ok=0 fail=0 escalate=0 skipped=<completed-count>`
   - print `REVIEW_STATUS=APPROVED`
   - print `REVIEW_ISSUE_COUNT=0`
   - print `REVIEW_P0_COUNT=0`
   - print `REVIEW_P1_COUNT=0`
   - print `REVIEW_PHASE_NOTE_FILE=none`
   - print `NEXT_COMMAND=rw-run`
   - stop.
5) If `#tool:agent/runSubagent` is unavailable:
   - print `runSubagent unavailable`
   - print `RW_ENV_UNSUPPORTED`
   - print `REVIEW_STATUS=FAILED`
   - print `REVIEW_ISSUE_COUNT=0`
   - print `REVIEW_P0_COUNT=0`
   - print `REVIEW_P1_COUNT=0`
   - print `REVIEW_PHASE_NOTE_FILE=none`
   - print `NEXT_COMMAND=rw-run`
   - stop.
6) Dispatch review subagents for each candidate task:
   - Determine mode using the deterministic policy above.
   - `PARALLEL` mode: fixed batch size 2.
   - `SEQUENTIAL` mode: dispatch one task at a time.
   - Print `REVIEW_EXECUTION_MODE=<PARALLEL|SEQUENTIAL>` before the first dispatch.
   - Before each dispatch print `RUNSUBAGENT_REVIEW_DISPATCH_BEGIN TASK-XX`.
   - After success print `RUNSUBAGENT_REVIEW_DISPATCH_OK TASK-XX`.
   - Subagent output contract (exactly one final line per task):
     - Optional structured finding lines before the final line:
       - `REVIEW_FINDING TASK-XX <P0|P1|P2>|<file>|<line>|<rule>|<fix>`
       - Use repository-relative `<file>` when possible; otherwise use `unknown`.
       - `<line>` must be a 1-based integer or `unknown`.
       - `<rule>` and `<fix>` must be concise single-line strings without `|`.
     - `REVIEW_RESULT TASK-XX OK`
     - or `REVIEW_RESULT TASK-XX FAIL: <root-cause>`
7) Aggregate subagent results and update `<PROGRESS>` once:
   - Parse all `REVIEW_FINDING TASK-XX ...` lines and aggregate counters:
     - `REVIEW_ISSUE_COUNT = total findings`
     - `REVIEW_P0_COUNT = findings with severity P0`
     - `REVIEW_P1_COUNT = findings with severity P1`
   - If a task result is `FAIL` and no structured finding exists for that task, synthesize one:
     - `P1|unknown|unknown|verification|<root-cause>`
   - If result is OK:
     - append `REVIEW_OK TASK-XX: verification passed`
   - If result is FAIL:
     - Count prior `REVIEW_FAIL TASK-XX` occurrences in active `<PROGRESS>` Log.
     - If prior count is 0:
       - append `REVIEW_FAIL TASK-XX (1/3): <root-cause>`
       - revert task status to `pending`
     - If prior count is 1:
       - append `REVIEW_FAIL TASK-XX (2/3): <root-cause>`
       - revert task status to `pending`
     - If prior count is 2 or more:
       - append `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required`
       - revert task status to `pending`
8) Determine normalized review status from aggregated counts:
   - If `escalate > 0`: `REVIEW_STATUS=FAILED`
   - Else if `fail > 0`: `REVIEW_STATUS=NEEDS_REVISION`
   - Else: `REVIEW_STATUS=APPROVED`
9) Write one review phase completion note under `<NOTES>`:
   - Ensure `<NOTES>` exists.
   - Create file: `REVIEW-PHASE-COMPLETE-YYYYMMDD-HHMM.md` (if exists, append `-v2`, `-v3`, ...).
   - Determine `STOP_REASON` for the note:
     - `REVIEW_BATCH_OK` when `REVIEW_STATUS=APPROVED`
     - `REVIEW_BATCH_FAIL` when `REVIEW_STATUS=NEEDS_REVISION` or `REVIEW_STATUS=FAILED`
   - Note content (concise, machine-friendly):
     - `# Review Phase Complete`
     - `- Timestamp: <YYYY-MM-DDTHH:MM:SSZ>`
     - `- PHASE: review`
     - `- REVIEW_STATUS: <APPROVED|NEEDS_REVISION|FAILED>`
     - `- STOP_REASON: <REVIEW_BATCH_OK|REVIEW_BATCH_FAIL>`
     - `- REVIEW_SUMMARY: total=<n> ok=<a> fail=<b> escalate=<c> skipped=<d>`
     - `- REVIEW_ISSUE_COUNT: <n>`
     - `- REVIEW_P0_COUNT: <n>`
     - `- REVIEW_P1_COUNT: <n>`
     - `- RUNSUBAGENT_REVIEW_DISPATCH_COUNT: <n>`
     - `- NEXT_COMMAND_CANDIDATE: <rw-archive|rw-run>`
10) Print summary:
   - `REVIEW_SUMMARY total=<n> ok=<a> fail=<b> escalate=<c> skipped=<d>`
   - `REVIEW_ISSUE_COUNT=<n>`
   - `REVIEW_P0_COUNT=<n>`
   - `REVIEW_P1_COUNT=<n>`
   - Print one line per aggregated finding:
     - `REVIEW_ISSUE <P0|P1|P2>|<file>|<line>|<rule>|<fix>`
   - `RUNSUBAGENT_REVIEW_DISPATCH_COUNT=<n>`
   - `REVIEW_STATUS=<APPROVED|NEEDS_REVISION|FAILED>`
   - `REVIEW_PHASE_NOTE_FILE=<path>`
11) If `REVIEW_STATUS` is `NEEDS_REVISION` or `FAILED`:
   - print `REVIEW_BATCH_FAIL`
   - print `NEXT_COMMAND=rw-run`
   - stop.
12) Otherwise:
   - print `REVIEW_BATCH_OK`
   - print `✅ Completed tasks verified`
   - print `NEXT_COMMAND=rw-archive`
   - stop.

<REVIEW_SUBAGENT_PROMPT>
You are a task reviewer subagent for one task (`TASK-XX`) under `TARGET_ROOT`.

Inputs:
- task id: `TASK-XX`
- tasks dir: `<TASKS>`
- progress file: `<PROGRESS>`
- plan file: `<PLAN>`

Rules:
- Find and read exactly one matching task file in `<TASKS>/TASK-XX-*.md`.
- Validate acceptance criteria coverage.
- Run verification commands listed in that task file.
- Read repository files only as needed for validation.
- Do not modify any file.
- Never call `#tool:agent/runSubagent` (nested calls are disallowed).
- Never fabricate outputs.

Output contract:
- Optional structured finding lines (zero or more):
  - `REVIEW_FINDING TASK-XX <P0|P1|P2>|<file>|<line>|<rule>|<fix>`
- End with exactly one line:
  - `REVIEW_RESULT TASK-XX OK`
  - or `REVIEW_RESULT TASK-XX FAIL: <root-cause>`
</REVIEW_SUBAGENT_PROMPT>
