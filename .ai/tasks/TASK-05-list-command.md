# TASK-05: List Command

## Dependencies: TASK-03

## Description

Implement the `list` command that displays all todos in a formatted output.

## Acceptance Criteria

- [ ] `todo list` displays all todos
- [ ] Shows `[✓]` for completed and `[ ]` for pending todos
- [ ] Displays id (first 8 chars), title, and status
- [ ] Shows "No todos found" message if list is empty
- [ ] Output is cleanly formatted and readable in terminal

## Files to Create/Modify

- `src/commands/list.ts`

## Verification

- Run `npm run build` and confirm no build errors.
- Run `node dist/src/index.js list` with an empty store and confirm "No todos found" is shown.
- Add a pending and a completed todo, then run `node dist/src/index.js list` and confirm `[ ]` and `[✓]` formatting plus shortened ids.
