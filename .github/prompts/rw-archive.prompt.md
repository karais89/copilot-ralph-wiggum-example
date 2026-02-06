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
- In PROGRESS.md keep:
  - Task Status table: pending/in-progress only
  - Log: most recent 20 entries only
- Move:
  - completed rows -> STATUS archive (append-only)
  - older logs -> LOG archive (append-only)
- Leave pointers in PROGRESS.md to the latest archive files.

Now perform the archive if needed and save the files.
