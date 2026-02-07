# TASK-11: Stats Command Handler

## Title
Implement stats command handler with text and JSON output

## Dependencies
- TASK-03 (Storage Layer)

## Description
Create a new command handler `src/commands/stats.ts` that computes and displays statistics about todos. The command should support two output modes:
- Default text mode: user-friendly formatted output
- JSON mode (with `--json` flag): machine-readable JSON object

## Acceptance Criteria
- `statsCommand()` function exported from `src/commands/stats.ts`
- Loads todos from storage using existing `loadTodos()` function
- Computes: total count, completed count, pending count, completion rate (0-100)
- Default output: formatted text with emoji/visual elements
- JSON output: valid JSON object with `{total, completed, pending, completionRate}`
- Completion rate calculated as: `(completed / total * 100)` or `0` if total is 0
- Completion rate rounded to 2 decimal places in JSON mode

## Files to Create/Modify
- Create: `src/commands/stats.ts`

## Verification
- `npm run build` passes without errors
- Manual test: create test data, run `todo stats` (text output visible)
- Manual test: run `todo stats --json` (valid JSON printed)
