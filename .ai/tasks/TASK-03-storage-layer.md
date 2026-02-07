# TASK-03: Storage Layer

## Dependencies: TASK-01, TASK-02

## Description

Implement the JSON file-based storage layer. This module handles reading from and writing to `data/todos.json`. It should create the data directory and file if they don't exist.

## Acceptance Criteria

- [ ] `loadTodos(): Promise<Todo[]>` — reads and parses todos from JSON file
- [ ] `saveTodos(todos: Todo[]): Promise<void>` — writes todos array to JSON file
- [ ] Auto-creates `data/` directory and `todos.json` if missing
- [ ] Returns empty array if file doesn't exist yet
- [ ] Handles JSON parse errors gracefully

## Files to Create/Modify

- `src/storage/json-store.ts`

## Verification

- Run `npm run build` and confirm no build errors.
- Run `node dist/index.js list` with no existing todo file and confirm it handles missing storage without crashing.
- Run `echo '{' > data/todos.json && node dist/index.js list` and confirm parse failure is surfaced as a controlled error message (no stack trace).
