# Copilot Simulation Test Guide

## Branch Setup

```bash
cd /Users/kaya/Documents/Github/context/context-github
git fetch --all
git checkout main
git pull --ff-only
```

## Run Lite Simulation

1. Open Copilot Chat (Agent mode recommended).
2. Open `/Users/kaya/Documents/Github/context/context-github/.ai/notes/COPILOT-LITE-SIMULATION-PROMPT.md`.
3. Copy the fenced prompt block and run it in Copilot Chat.
4. Save the output report to:
   `/Users/kaya/Documents/Github/context/context-github/.ai/LITE-SIMULATION-REPORT-YYYYMMDD.md`

## Run Strict Simulation

1. Open `/Users/kaya/Documents/Github/context/context-github/.ai/notes/COPILOT-STRICT-SIMULATION-PROMPT.md`.
2. Copy the fenced prompt block and run it in Copilot Chat.
3. Save the output report to:
   `/Users/kaya/Documents/Github/context/context-github/.ai/STRICT-SIMULATION-REPORT-YYYYMMDD.md`

## Optional Diff Check

If you run simulations on a temporary branch, compare it with `main`:

```bash
cd /Users/kaya/Documents/Github/context/context-github
git diff --stat main..HEAD
```

## Notes

- Do not run Lite and Strict orchestrators concurrently on the same workspace.
- Lite mode does not stop automatically on archive thresholds; it only warns. Pause manually before running `rw-archive`.
- If strict run is active, do not trigger `rw-archive` in parallel.
