# TASK-06: Update (Done) Command

## Dependencies: TASK-03

## Description

Implement the `done` command that toggles the completed status of a todo.

## Acceptance Criteria

- [ ] `todo done <id>` toggles the `completed` field of the matching todo
- [ ] Matches by full id or prefix (first few characters)
- [ ] Prints confirmation with updated status
- [ ] Shows error message if no todo matches the given id

## Files to Create/Modify

- `src/commands/update.ts`

## Verification

- Run `npm run build` and confirm no build errors.
- Run `node dist/index.js done <full-id>` and confirm status toggles.
- Run `node dist/index.js done <id-prefix>` and confirm prefix matching works.
- Run `node dist/index.js done unknown` and confirm user-friendly not-found error is shown.
