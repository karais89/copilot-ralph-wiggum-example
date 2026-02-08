Title: Add `--json` flag to `stats` command

Dependencies: TASK-11, TASK-12

Description:
- Add a `--json` (or `-j`) option to the existing `stats` CLI command so that when provided, the command outputs machine-parseable JSON instead of (or in addition to) human-friendly text.

Acceptance Criteria:
- `node dist/src/index.js stats --json` exits 0 and prints valid JSON to stdout.
- When `--json` is not provided, existing text output remains unchanged.

Files to Create/Modify:
- `src/commands/stats.ts` (add option handling and JSON output branch)
- `src/index.ts` (if CLI option wiring is required)

Verification:
- Manual run: `node dist/src/index.js stats --json` and `node dist/src/index.js stats` show expected outputs.
- Unit/integration tests added in TASK-16 pass.
