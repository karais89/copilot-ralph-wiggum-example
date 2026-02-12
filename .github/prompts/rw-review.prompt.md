---
name: rw-review
description: "Manual reviewer: subagent-backed batch validation for completed tasks with REVIEW_OK/REVIEW_FAIL/REVIEW-ESCALATE updates"
agent: agent
argument-hint: "No input. Target root is resolved by .ai/runtime/rw-active-target-id.txt (preferred) or .ai/runtime/rw-active-target-root.txt (fallback)."
---

Language policy reference: `<CONTEXT>`

Quick summary:
- Run this manually after `rw-run` to review completed tasks in batch.
- Dispatch review subagents per task (parallel batches when safe/available).
- Write review outcomes to `PROGRESS` using `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`.

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
  - `<PLAN>` = `TARGET_ROOT/.ai/PLAN.md`
  - `<TASKS>` = `TARGET_ROOT/.ai/tasks/`
  - `<PROGRESS>` = `TARGET_ROOT/.ai/PROGRESS.md`

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
- Only update review-related state in `<PROGRESS>`:
  - `REVIEW_OK TASK-XX: verification passed`
  - `REVIEW_FAIL TASK-XX (n/3): <root-cause>`
  - `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required`
  - `REVIEW-ESCALATE-RESOLVED TASK-XX: <resolution>` (manual recovery path, user-driven)
- Never fabricate review results.
- Review all currently `completed` tasks in active Task Status.
- This prompt must dispatch `#tool:agent/runSubagent` for per-task validation.
- Subagents must not modify repository files; orchestrator writes `<PROGRESS>` only after collecting results.
- Each review candidate task must be dispatched exactly once in the current review run.

Procedure:
1) Read `<PROGRESS>` and collect all `completed` tasks in active `Task Status`.
2) If no completed task exists, print `REVIEW_TARGET_MISSING` and stop.
3) Build review candidates:
   - For each completed task (`TASK-XX`), locate its latest completion log (`TASK-XX completed`).
   - If there is already a later review log for the same task (`REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`), skip it as already reviewed.
   - Remaining tasks are the review candidate set.
4) If candidate set is empty:
   - print `REVIEW_NOTHING_TO_DO`
   - print `REVIEW_SUMMARY total=0 ok=0 fail=0 escalate=0 skipped=<completed-count>`
   - stop.
5) If `#tool:agent/runSubagent` is unavailable:
   - print `runSubagent unavailable`
   - print `RW_ENV_UNSUPPORTED`
   - stop.
6) Dispatch review subagents for each candidate task:
   - Preferred execution: parallel batches (batch size up to 3) when concurrency is supported and verification commands are parallel-safe.
   - If commands share mutable resources (fixed port, shared DB/file lock, global cache mutation), force sequential dispatch.
   - Fallback: sequential dispatch per task.
   - Before each dispatch print `RUNSUBAGENT_REVIEW_DISPATCH_BEGIN TASK-XX`.
   - After success print `RUNSUBAGENT_REVIEW_DISPATCH_OK TASK-XX`.
   - Subagent output contract (exactly one final line per task):
     - `REVIEW_RESULT TASK-XX OK`
     - or `REVIEW_RESULT TASK-XX FAIL: <root-cause>`
7) Aggregate subagent results and update `<PROGRESS>` once:
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
8) Print summary:
   - `REVIEW_SUMMARY total=<n> ok=<a> fail=<b> escalate=<c> skipped=<d>`
   - `RUNSUBAGENT_REVIEW_DISPATCH_COUNT=<n>`
9) If any fail/escalate occurred:
   - print `REVIEW_BATCH_FAIL`
   - stop.
10) Otherwise:
   - print `REVIEW_BATCH_OK`
   - print `✅ Completed tasks verified`
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
- End with exactly one line:
  - `REVIEW_RESULT TASK-XX OK`
  - or `REVIEW_RESULT TASK-XX FAIL: <root-cause>`
</REVIEW_SUBAGENT_PROMPT>
