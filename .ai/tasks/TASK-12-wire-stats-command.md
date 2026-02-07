# TASK-12: Wire Stats Command to CLI

## Title
Register stats command in CLI entry point

## Dependencies
- TASK-11 (Stats Command Handler)

## Description
Add the `stats` command to the CLI entry point in `src/index.ts`. The command should:
- Accept an optional `--json` flag
- Call the `statsCommand()` handler with the flag value
- Handle errors gracefully

## Acceptance Criteria
- Import `statsCommand` from `src/commands/stats.ts`
- Register command: `todo stats [options]`
- Add option: `--json` description "Output stats as JSON"
- Action handler passes the `--json` flag to `statsCommand()`
- Wrapped in try/catch with error handling (consistent with other commands)
- Help text displays correctly: `todo stats --help`

## Files to Create/Modify
- Modify: `src/index.ts`

## Verification
- `npm run build` passes
- `todo --help` lists stats command
- `todo stats --help` shows command help with --json option
- `todo stats` displays text output
- `todo stats --json` displays JSON output
