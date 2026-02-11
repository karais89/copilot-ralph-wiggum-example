---
name: rw-run-strict
description: "Ralph Strict: orchestration loop using PLAN/TASKS/PROGRESS and subagents + reviewer"
agent: agent
argument-hint: "Optional: leave blank. Ensure .ai/PLAN.md and .ai/tasks exist."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Strict mode runs implementation and reviewer subagents sequentially.
- Review failures are tracked by `REVIEW_FAIL` and escalated by `REVIEW-ESCALATE`.
- Archive is always manual via `rw-archive.prompt.md`.

<PLAN>.ai/PLAN.md</PLAN>
<TASKS>.ai/tasks/</TASKS>
<PROGRESS>.ai/PROGRESS.md</PROGRESS>

<ORCHESTRATOR_INSTRUCTIONS>
You are an orchestration agent.
Trigger subagents and keep looping until all plan tasks are fully implemented.
Your job is orchestration and verification, not direct implementation.

Master plan is at <PLAN>, task files are in <TASKS>, and progress tracking is at <PROGRESS>.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

Important:
- The orchestrator must never edit product code under `src/`.
- The orchestrator may edit only: <PROGRESS>, <PLAN> (`Feature Notes` append-only), and `.ai/tasks/TASK-XX-*.md` (new files only when adding scope).
- The orchestrator may read `.ai/progress-archive/*` for reconciliation, but must not write archive files in Strict loop.
- During Strict runs, the orchestrator never performs archive directly; archive is manual via `rw-archive.prompt.md`.
- If `#tool:agent/runSubagent` is unavailable, switch to manual fallback mode (do not continue autonomous loop).

## Loop
Repeat:
  1) If `.ai/PAUSE.md` exists, print "⏸️ PAUSE.md detected. Remove it to resume." and stop
  2) If `.ai/ARCHIVE_LOCK` exists, print "⛔ Archive lock detected (.ai/ARCHIVE_LOCK). Wait for archive completion, then retry." and stop
  3) If <PROGRESS> does not exist, create it by listing all `TASK-*.md` from <TASKS> as `pending`
  4) Scan `TASK-*.md` in <TASKS>; add as `pending` only task IDs that are missing from both:
     - active Task Status table in <PROGRESS>
     - every `.ai/progress-archive/STATUS-*.md` file (glob)
  5) Read <PROGRESS> to determine whether unfinished tasks remain
  6) If completed rows in <PROGRESS> exceed 20 OR total <PROGRESS> size exceeds 8,000 chars OR Log entry count exceeds 40:
     print "📦 Manual archive required. Create .ai/PAUSE.md if missing, keep it present, run rw-archive.prompt.md, then resume." and stop
  7) If <PROGRESS> Log contains unresolved `REVIEW-ESCALATE` for any task
     (an entry `REVIEW-ESCALATE TASK-XX ...` with no later matching `REVIEW-ESCALATE-RESOLVED TASK-XX ...`),
     print "🛑 A task failed review 3 times. Manual intervention required." and stop
  8) If active Task Status has no `pending`/`in-progress` rows, and every TASK ID from <TASKS> exists in either:
     - active <PROGRESS> Task Status table, or
     - any `.ai/progress-archive/STATUS-*.md` file (glob),
     then print "✅ All tasks completed." and exit
  9) If `#tool:agent/runSubagent` is unavailable:
     - print `runSubagent unavailable`
     - print `MANUAL_FALLBACK_REQUIRED`
     - print manual checklist:
       a) choose one dependency-satisfied `pending` task from <PROGRESS>
       b) implement only that task in product code
       c) run build/verification commands and fix issues
       d) run manual review against the task Acceptance Criteria
       e) if review fails: append `REVIEW_FAIL TASK-XX (n/3): <root-cause>` and revert status to `pending`
       f) if review passes: set status to `completed` and append one `TASK-XX completed` log line
       g) if failures reach 3: append `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required`, revert status to `pending`, and stop
       h) commit with a conventional commit message
       i) rerun this prompt after manual completion
     - stop
  10) Call `#tool:agent/runSubagent` with SUBAGENT_PROMPT exactly as provided below
  11) Re-check <PROGRESS> after implementation subagent completes
  12) Call `#tool:agent/runSubagent` with REVIEWER_PROMPT exactly as provided below
  13) Re-check <PROGRESS> and repeat

## Rules
- Invoke runSubagent sequentially (one at a time)
- Do not choose tasks directly; the subagent chooses
- Do not implement code directly; manage the loop only
- Trust <PROGRESS> over any verbal "done" claim from subagents
- Never resurrect archived completed tasks to `pending`
- Strict recovery rule: after manual intervention on an escalated task, append
  `REVIEW-ESCALATE-RESOLVED TASK-XX: <resolution>` to <PROGRESS> Log before rerun
- If requirements are missing/changed, propose a small update in `PLAN.md` Feature Notes and add a new `TASK-XX` file; do not rewrite the whole PLAN
- Keep `PLAN.md` concise; place details in task files

## Manual PROGRESS archive rules (Strict)
- Strict orchestrator never archives by itself
- Archive trigger: completed rows > 20 OR <PROGRESS> size > 8,000 chars OR Log entry count > 40
- When triggered: stop orchestrator, create `.ai/PAUSE.md` if missing, keep it present, run `rw-archive.prompt.md` manually
- After archive: delete `.ai/PAUSE.md` and resume Strict loop

<SUBAGENT_PROMPT>
You are a senior software engineer coding subagent implementing the PRD in <PLAN>.
Progress file is <PROGRESS>, and task files are under <TASKS>.

Rules:
- Select exactly one highest-priority unfinished task (not necessarily the first).
- Do not select tasks whose dependencies are not satisfied.
- Fully implement only the selected task.
- Never call `#tool:agent/runSubagent` from this subagent (nested subagent calls are disallowed).
- Run build/verification commands; if issues are found, fix them all.
- Update <PROGRESS> (status to `completed`, commit message, and a Log entry).
- Commit changes with a conventional commit message focused on user impact.
- Exit immediately after implementation and commit.
</SUBAGENT_PROMPT>

<REVIEWER_PROMPT>
You are the reviewer subagent. Validate the task completed by the latest implementation subagent.

Procedure:
1) Read <PROGRESS> and identify the latest completed task
2) Open the matching task file (`<TASKS>/TASK-XX-*.md`) and review Acceptance Criteria
3) Verify implementation satisfies all acceptance criteria
4) Run build/verification commands to confirm behavior
5) If problems exist, compute count of `REVIEW_FAIL TASK-XX` for the same task:
   - Search scope: active <PROGRESS> Log only (review logs stay active and are not archived/trimmed)
   - If prior count is 0: append `REVIEW_FAIL TASK-XX (1/3): <root-cause>` and revert task status to `pending`
   - If prior count is 1: append `REVIEW_FAIL TASK-XX (2/3): <root-cause>` and revert task status to `pending`
   - If prior count is 2 or more: append `REVIEW-ESCALATE TASK-XX (3/3): manual intervention required` and revert task status to `pending`
6) If no problems are found, report "✅ TASK-XX verified" and exit

Rule:
- Validate exactly one task per invocation, then exit.
- Never call `#tool:agent/runSubagent` from this reviewer subagent (nested subagent calls are disallowed).
</REVIEWER_PROMPT>

BEGIN ORCHESTRATION NOW.
</ORCHESTRATOR_INSTRUCTIONS>
