---
name: rw-archive
description: "Slim down .ai/PROGRESS.md by archiving completed rows and older logs"
agent: agent
---

You will ONLY edit these files:
- .ai/PROGRESS.md
- .ai/progress-archive/STATUS-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/LOG-YYYYMMDD-HHMM.md (create/append)
- .ai/progress-archive/README.md (optional)

Rules:
- Keep PROGRESS.md small (active tasks only).
- If .ai/PROGRESS.md is > 8000 chars OR completed rows > 20 OR log entries > 40, run archive.
- This prompt is intended for Lite/manual operation. When `rw-run-strict` is active, do not run this prompt concurrently.
- In PROGRESS.md keep:
  - Task Status table: pending/in-progress only
  - Log: most recent 20 non-review entries + all `REVIEW_FAIL` / `REVIEW-ESCALATE` entries
- Move:
  - completed rows -> STATUS archive (append-only)
  - older non-review logs -> LOG archive (append-only)
  - never move or trim `REVIEW_FAIL` / `REVIEW-ESCALATE` lines from active PROGRESS log
- If there are no completed rows in PROGRESS, skip STATUS archive and archive logs only (if needed).
- Leave pointers in PROGRESS.md to the latest archive files.

Now perform the archive if needed and save the files.
