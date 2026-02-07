# TASK-13: Stats Command Integration Test

## Title
End-to-end testing of stats command

## Dependencies
- TASK-12 (Wire Stats Command)

## Description
Verify the stats command works correctly in real-world usage scenarios. This includes both text and JSON output modes with various data states.

## Acceptance Criteria
- Test with empty todos: stats show 0 for all metrics
- Test with mixed todos (some completed, some pending): stats are accurate
- Text output is human-readable and formatted
- JSON output is valid JSON and parseable
- Completion rate calculation is accurate (0-100 range)
- No crashes or unhandled errors

## Files to Create/Modify
- None (testing only)

## Verification
- Create test data: `todo add "Task 1"`, `todo add "Task 2"`, `todo done <id1>`
- Run `todo stats` — verify text output shows: 2 total, 1 completed, 1 pending, 50% rate
- Run `todo stats --json` — verify valid JSON with correct values
- Parse JSON output: `todo stats --json | jq .` (or manual verification)
- Run `todo stats` on empty data — verify graceful handling (0 counts)
- Run `todo --help` — verify stats command listed
- All build and runtime checks pass
