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
- Keep all review logs (`REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED`) in active PROGRESS.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

You will ONLY edit these files:
- .ai/PROGRESS.md
- .ai/PAUSE.md (optional create for archive preflight)
- .ai/ARCHIVE_LOCK (create/delete for lock)
- .ai/progress-archive/STATUS-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/LOG-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/README.md (optional)

Rules:
- Before any archive operation, ensure `.ai/PAUSE.md` exists.
  - If `.ai/PAUSE.md` is missing, resolve once via `#tool:vscode/askQuestions` single choice (in resolved user-document language from `.ai/CONTEXT.md`):
    - `Create .ai/PAUSE.md and continue rw-archive`
    - `Cancel`
  - If `#tool:vscode/askQuestions` is unavailable, ask the same single-choice confirmation in chat once.
  - If user selects create, create `.ai/PAUSE.md` with one timestamp line and continue.
  - If user selects cancel or no valid selection is obtained after that single interaction, stop immediately with:
    "⛔ rw-run may still be active. Create .ai/PAUSE.md first, then retry rw-archive."
- If `.ai/ARCHIVE_LOCK` already exists, stop immediately with:
  "⛔ Archive lock detected (.ai/ARCHIVE_LOCK). Another archive may be running."
- Before mutating PROGRESS or archive files, create `.ai/ARCHIVE_LOCK` with a timestamp line.
- On successful completion, delete `.ai/ARCHIVE_LOCK`.
- If archive cannot complete safely, keep `.ai/ARCHIVE_LOCK` and report manual recovery steps.
- Keep PROGRESS.md small (active tasks only).
- If .ai/PROGRESS.md is > 8000 chars OR completed rows > 20 OR log entries > 40, run archive.
- This prompt is the only archive path for both Lite and Strict. Always run manually while `.ai/PAUSE.md` is present.
- In PROGRESS.md keep:
  - Task Status table: pending/in-progress only
  - Log: most recent 20 non-review entries + all `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` entries
- Move:
  - completed rows -> STATUS archive (append-only)
  - older non-review logs -> LOG archive (append-only)
  - never move or trim `REVIEW_FAIL` / `REVIEW-ESCALATE` / `REVIEW-ESCALATE-RESOLVED` lines from active PROGRESS log
- If there are no completed rows in PROGRESS, skip STATUS archive and archive logs only (if needed).
- Leave pointers in PROGRESS.md to the latest archive files.

Now perform the archive if needed and save the files.
