---
name: rw-archive
description: "Slim down .ai/PROGRESS.md by archiving completed rows and older logs"
agent: agent
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Manually archive completed rows and older logs from `.ai/PROGRESS.md`.
- Require `.ai/PAUSE.md` before archive.
- Use `.ai/ARCHIVE_LOCK` to prevent concurrent archive runs.
- Keep all review logs (`REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED`) in active PROGRESS.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

You will ONLY edit these files:
- .ai/PROGRESS.md
- .ai/PAUSE.md (optional create/delete for archive preflight)
- .ai/ARCHIVE_LOCK (create/delete for lock)
- .ai/progress-archive/STATUS-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/LOG-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/README.md (optional)

Rules:
- First, inspect active `.ai/PROGRESS.md` and compute:
  - total character count
  - completed Task Status row count
  - Log entry count
  Then set `archive_needed=true` if any condition is met:
  - char count > 8000
  - completed rows > 20
  - log entries > 40
- If `archive_needed=false`, resolve force-run once via `#tool:vscode/askQuestions` single choice (in resolved user-document language from `.ai/CONTEXT.md`):
  - `Force archive now`
  - `Skip archive (recommended)`
  - If `#tool:vscode/askQuestions` is unavailable, ask the same single-choice confirmation in chat once.
  - If `Force archive now` is selected, set `force_archive=true` and continue.
  - If `Skip archive` is selected or no valid selection is obtained after that single interaction:
    - do not create `.ai/ARCHIVE_LOCK`
    - do not create archive output files
    - if `.ai/PAUSE.md` contains exact line `created-by: rw-archive-preflight`, delete `.ai/PAUSE.md` before finishing
    - finish with a no-op summary
- Do not use open-ended follow-up text like "if you want forced archive, tell me". Use the single-choice askQuestions flow above.
- Before any archive operation, ensure `.ai/PAUSE.md` exists.
  - If `.ai/PAUSE.md` is missing, resolve once via `#tool:vscode/askQuestions` single choice (in resolved user-document language from `.ai/CONTEXT.md`):
    - `Create .ai/PAUSE.md and continue rw-archive`
    - `Cancel`
  - If `#tool:vscode/askQuestions` is unavailable, ask the same single-choice confirmation in chat once.
  - If user selects create, create `.ai/PAUSE.md` with:
    - one timestamp line
    - one ownership marker line: `created-by: rw-archive-preflight`
    and continue.
  - If user selects cancel or no valid selection is obtained after that single interaction, stop immediately with:
    "⛔ rw-run may still be active. Create .ai/PAUSE.md first, then retry rw-archive."
- If `.ai/ARCHIVE_LOCK` already exists, stop immediately with:
  "⛔ Archive lock detected (.ai/ARCHIVE_LOCK). Another archive may be running."
- Before mutating PROGRESS or archive files, create `.ai/ARCHIVE_LOCK` with a timestamp line.
- On successful completion, delete `.ai/ARCHIVE_LOCK`.
- On successful completion, if `.ai/PAUSE.md` contains exact line `created-by: rw-archive-preflight`, delete `.ai/PAUSE.md` automatically before finishing.
- If the marker line is absent, do not delete `.ai/PAUSE.md`.
- If archive cannot complete safely, keep `.ai/ARCHIVE_LOCK` and report manual recovery steps.
- Keep PROGRESS.md small (active tasks only).
- Run archive only when `archive_needed=true` or `force_archive=true`.
- This prompt is the only archive path for the single `rw-run` policy. Always run manually while `.ai/PAUSE.md` is present.
- In PROGRESS.md keep:
  - Task Status table: pending/in-progress only
  - Log: most recent 20 non-review entries + all `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` entries
- Move:
  - completed rows -> STATUS archive (append-only)
  - older non-review logs -> LOG archive (append-only)
  - never move or trim `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` lines from active PROGRESS log
- If there are no completed rows in PROGRESS, skip STATUS archive and archive logs only (if needed).
- Leave pointers in PROGRESS.md to the latest archive files.

Now perform the archive if needed and save the files.
