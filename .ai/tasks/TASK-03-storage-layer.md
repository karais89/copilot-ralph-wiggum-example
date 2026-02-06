# TASK-03: Storage Layer

## Status: pending

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
