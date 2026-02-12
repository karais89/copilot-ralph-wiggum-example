---
name: rw-doctor
description: "Preflight environment check for RW autonomous orchestration (runSubagent/top-level/git/.ai)"
agent: agent
argument-hint: "No input. Target root is resolved by .ai/runtime/rw-active-target-id.txt (preferred) or .ai/runtime/rw-active-target-root.txt (fallback)."
---

Language policy reference: `<CONTEXT>`

Quick summary:
- Run this before `rw-run`.
- Validate environment prerequisites for autonomous mode.
- Print machine-readable PASS/FAIL tokens and blocker list.

Path resolution (mandatory before checks):
- Follow `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md` exactly.
- Resolve target metadata via `scripts/rw-resolve-target-root.sh` against workspace root.
- Resolve paths from `TARGET_ROOT`:
  - `<CONTEXT>` = `TARGET_ROOT/.ai/CONTEXT.md`
  - `<AI_ROOT>` = `TARGET_ROOT/.ai/`
  - `<RUNTIME_DIR>` = `TARGET_ROOT/.ai/runtime/`
  - `<DOCTOR_STAMP>` = `TARGET_ROOT/.ai/runtime/rw-doctor-last-pass.env`
  - `<TASKS>` = `TARGET_ROOT/.ai/tasks/`
  - `<FEATURES>` = `TARGET_ROOT/.ai/features/`
  - `<PLAN>` = `TARGET_ROOT/.ai/PLAN.md`
  - `<PROGRESS>` = `TARGET_ROOT/.ai/PROGRESS.md`

Path guard (before Step 0):
1) Validate `TARGET_ROOT`:
   - it must be a non-empty absolute path
   - it must exist and be readable as a directory
2) If validation fails, stop immediately and output:
   - first line exactly: `RW_TARGET_ROOT_INVALID`
   - second line: `<short reason>`
   - third line: `Fix .ai/runtime/rw-active-target-id.txt or .ai/runtime/rw-active-target-root.txt and rerun rw-doctor.`

Step 0 (Mandatory):
1) Read `<CONTEXT>` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes, except auto-repair of target-pointer files during path resolution (`TARGET_ACTIVE_ID_FILE`, `TARGET_REGISTRY_DIR/*`, `TARGET_POINTER_FILE`).

You are an RW preflight checker. Do not implement code and do not edit repository files, except writing `<DOCTOR_STAMP>` on PASS.

Checks (all required):
1) Top-level turn check:
   - This prompt must run from a top-level Copilot Chat turn.
   - If this prompt is being executed in a nested/subagent context, mark FAIL with token `TOP_LEVEL_REQUIRED`.
2) runSubagent availability:
   - Verify `#tool:agent/runSubagent` is available in the current environment.
   - Require a concrete probe:
     - Attempt one minimal call to `#tool:agent/runSubagent` with a no-op prompt that returns `RUNSUBAGENT_OK`.
     - Accept PASS only when the probe call is actually invoked and returns `RUNSUBAGENT_OK`.
   - If probe cannot run or returns any other result, mark FAIL with token `RW_ENV_UNSUPPORTED`.
3) Git repository readiness:
   - Verify `TARGET_ROOT` is inside a git repository.
   - If not, mark FAIL with token `GIT_REPO_MISSING`.
4) Workspace structure readiness:
   - Verify `<AI_ROOT>` exists and is readable.
   - Verify `<TASKS>` exists and is readable.
   - Verify `<FEATURES>` exists and is readable.
   - If missing/unreadable, mark FAIL with token `RW_WORKSPACE_MISSING`.
5) Core file readability:
   - Verify `<PLAN>` and `<PROGRESS>` are readable if they exist.
   - If either exists but unreadable, mark FAIL with token `RW_CORE_FILE_UNREADABLE`.

Result rules:
- If any check fails:
  - First line must be exactly: `RW_DOCTOR_BLOCKED`
  - Then print one line per failed token in this format:
    - `<TOKEN>: <short reason>`
  - Then print:
    - `Run rw-init or rw-new-project to bootstrap, then rerun rw-run.`
    - `NEXT_COMMAND=rw-run`
  - Stop.
- If all checks pass:
  - Persist doctor pass stamp:
    - ensure `<RUNTIME_DIR>` exists (create if missing)
    - overwrite `<DOCTOR_STAMP>` with:
      - `RW_DOCTOR_PASS=1`
      - `TARGET_ID=<TARGET_ID>`
      - `TARGET_ROOT=<TARGET_ROOT>`
      - `CHECKED_AT=<YYYY-MM-DDTHH:MM:SSZ>`
    - if write fails, treat as FAIL:
      - first line: `RW_DOCTOR_BLOCKED`
      - token line: `RW_DOCTOR_STAMP_WRITE_FAILED: <short reason>`
      - then:
        - `Fix runtime directory permissions and rerun rw-run.`
        - `NEXT_COMMAND=rw-run`
      - stop
  - First line must be exactly: `RW_DOCTOR_PASS`
  - Then print:
    - `Target root: <TARGET_ROOT>`
    - `Target id: <TARGET_ID>`
    - `Target active id file: <TARGET_ACTIVE_ID_FILE>`
    - `Target pointer file (fallback): <TARGET_POINTER_FILE>`
    - `Doctor stamp file: <DOCTOR_STAMP>`
    - `Top-level turn: PASS`
    - `runSubagent: PASS`
    - `Git repository: PASS`
    - `Workspace structure: PASS`
    - `Core files readability: PASS`
  - Final lines:
    - `Safe to run rw-run.`
    - `NEXT_COMMAND=rw-run`
