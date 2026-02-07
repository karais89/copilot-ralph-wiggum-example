# TASK-07: Delete Command

## Dependencies: TASK-03

## Description

Implement the `delete` command that permanently removes a todo from storage.

## Acceptance Criteria

- [ ] `todo delete <id>` removes the matching todo
- [ ] Matches by full id or prefix
- [ ] Prints confirmation after successful deletion
- [ ] Shows error message if no todo matches the given id

## Files to Create/Modify

- `src/commands/delete.ts`

## Verification

- Run `npm run build` and confirm no build errors.
- Run `node dist/index.js delete <full-id>` and confirm the todo is removed.
- Run `node dist/index.js delete <id-prefix>` and confirm prefix matching works.
- Run `node dist/index.js delete unknown` and confirm user-friendly not-found error is shown.
