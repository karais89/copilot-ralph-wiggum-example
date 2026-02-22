---
name: rw-archive
description: "Slim down .ai/PROGRESS.md by archiving completed rows and older logs"
agent: agent
---

Language policy reference: `<CONTEXT>`

Quick summary:
- Manually archive completed rows and older logs from `<PROGRESS>`.
- Require `<PAUSE>` before archive.
- Use `<ARCHIVE_LOCK>` to prevent concurrent archive runs.
- Keep all review logs (`REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED`) in active PROGRESS.

Path resolution (mandatory before Step 0):
- Follow `.github/prompts/shared/RW-TARGET-ROOT-RESOLUTION.md` exactly.
- Resolve target metadata via `scripts/orchestration/rw-resolve-target-root.sh` against workspace root.
- Resolve paths from `TARGET_ROOT`:
  - `<CONTEXT>` = `TARGET_ROOT/.ai/CONTEXT.md`
  - `<PROGRESS>` = `TARGET_ROOT/.ai/PROGRESS.md`
  - `<PAUSE>` = `TARGET_ROOT/.ai/PAUSE.md`
  - `<ARCHIVE_LOCK>` = `TARGET_ROOT/.ai/ARCHIVE_LOCK`
  - `<ARCHIVE_DIR>` = `TARGET_ROOT/.ai/progress-archive/`

Step 0 (Mandatory):
1) Validate `TARGET_ROOT`:
   - it must be a non-empty absolute path
   - it must exist and be readable as a directory
2) If validation fails, stop immediately and output exactly: `RW_TARGET_ROOT_INVALID`
3) Read `<CONTEXT>` first.
4) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
5) Validate language policy internally and proceed silently (no confirmation line).
6) Do not modify any file before Step 0 completes, except auto-repair of target-pointer files during path resolution (`TARGET_ACTIVE_ID_FILE`, `TARGET_REGISTRY_DIR/*`, `TARGET_POINTER_FILE`).

You will ONLY edit these files:
- `<PROGRESS>`
- `<PAUSE>` (optional create/delete for archive preflight)
- `<ARCHIVE_LOCK>` (create/delete for lock)
- `<ARCHIVE_DIR>/STATUS-YYYYMMDD-HHMM.md` (create/append)
- `<ARCHIVE_DIR>/LOG-YYYYMMDD-HHMM.md` (create/append)
- `<ARCHIVE_DIR>/README.md` (optional)

Rules:
- Interactive fallback must follow `.github/prompts/shared/RW-INTERACTIVE-POLICY.md`.
- On every exit path, print one final machine-readable line:
  - `NEXT_COMMAND=<rw-run|rw-archive>`
- First, inspect active `<PROGRESS>` and compute:
  - total character count
  - completed Task Status row count
  - Log entry count
  Then set `archive_needed=true` if any condition is met:
  - char count > 8000
  - completed rows > 20
  - log entries > 40
- If `archive_needed=false`, resolve force-run once via `#tool:vscode/askQuestions` single choice (in resolved user-document language from `<CONTEXT>`):
  - `Force archive now`
  - `Skip archive (recommended)`
  - If `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/shared/RW-INTERACTIVE-POLICY.md`.
  - If `Force archive now` is selected, set `force_archive=true` and continue.
  - If `Skip archive` is selected or no valid selection is obtained after that single interaction:
    - do not create `<ARCHIVE_LOCK>`
    - do not create archive output files
    - if `<PAUSE>` contains exact line `created-by: rw-archive-preflight`, delete `<PAUSE>` before finishing
    - finish with a no-op summary
    - print `NEXT_COMMAND=rw-run`
- Do not use open-ended follow-up text like "if you want forced archive, tell me". Use the single-choice askQuestions flow above.
- Before any archive operation, ensure `<PAUSE>` exists.
  - If `<PAUSE>` is missing, resolve once via `#tool:vscode/askQuestions` single choice (in resolved user-document language from `<CONTEXT>`):
    - `Create TARGET_ROOT/.ai/PAUSE.md and continue rw-archive`
    - `Cancel`
  - If `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/shared/RW-INTERACTIVE-POLICY.md`.
  - If user selects create, create `<PAUSE>` with:
    - one timestamp line
    - one ownership marker line: `created-by: rw-archive-preflight`
    and continue.
  - If user selects cancel or no valid selection is obtained after that single interaction, stop immediately with:
    "⛔ rw-run may still be active. Create TARGET_ROOT/.ai/PAUSE.md first, then retry rw-archive."
    and print:
    - `NEXT_COMMAND=rw-archive`
- If `<ARCHIVE_LOCK>` already exists, stop immediately with:
  "⛔ Archive lock detected (TARGET_ROOT/.ai/ARCHIVE_LOCK). Another archive may be running."
  and print:
  - `NEXT_COMMAND=rw-archive`
- Before mutating `<PROGRESS>` or archive files, create `<ARCHIVE_LOCK>` with a timestamp line.
- On successful completion, delete `<ARCHIVE_LOCK>`.
- On successful completion, if `<PAUSE>` contains exact line `created-by: rw-archive-preflight`, delete `<PAUSE>` automatically before finishing.
- If the marker line is absent, do not delete `<PAUSE>`.
- If archive cannot complete safely, keep `<ARCHIVE_LOCK>` and report manual recovery steps.
- Keep `<PROGRESS>` small (active tasks only).
- Run archive only when `archive_needed=true` or `force_archive=true`.
- This prompt is the only archive path for the single `rw-run` policy. Always run manually while `<PAUSE>` is present.
- In `<PROGRESS>` keep:
  - Task Status table: pending/in-progress only
  - Log: most recent 20 non-review entries + all `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` entries
- Move:
  - completed rows -> STATUS archive under `<ARCHIVE_DIR>` (append-only)
  - older non-review logs -> LOG archive under `<ARCHIVE_DIR>` (append-only)
  - never move or trim `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` lines from active PROGRESS log
- If there are no completed rows in `<PROGRESS>`, skip STATUS archive and archive logs only (if needed).
- Leave pointers in `<PROGRESS>` to the latest archive files.

Now perform the archive if needed and save the files.

Output format at end:
- `ARCHIVE_RESULT=<applied|skipped|blocked>`
- `STATUS_ARCHIVE_FILE=<path|none>`
- `LOG_ARCHIVE_FILE=<path|none>`
- `NEXT_COMMAND=<rw-run|rw-archive>`
