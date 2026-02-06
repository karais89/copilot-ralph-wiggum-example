# TASK-09: Error Handling

## Dependencies: TASK-08

## Description

Add comprehensive error handling across all commands and the main entry point. Ensure the app never crashes with an unhandled exception.

## Acceptance Criteria

- [ ] Global uncaught exception handler in entry point
- [ ] All commands wrap execution in try/catch
- [ ] User-friendly error messages (no raw stack traces in production)
- [ ] Missing argument errors show usage hint
- [ ] File system errors (permissions, disk full) handled gracefully

## Files to Create/Modify

- `src/index.ts` (global handler)
- `src/commands/add.ts`
- `src/commands/list.ts`
- `src/commands/update.ts`
- `src/commands/delete.ts`
