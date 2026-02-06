# TASK-02: Data Model Definition

## Dependencies: TASK-01

## Description

Define the Todo data model as a TypeScript interface. This is the core type used across all commands and storage operations.

## Acceptance Criteria

- [ ] `Todo` interface defined with fields: `id` (string), `title` (string), `completed` (boolean), `createdAt` (string)
- [ ] Type is exported and usable from other modules
- [ ] A helper function `createTodo(title: string): Todo` that generates id and createdAt automatically

## Files to Create/Modify

- `src/models/todo.ts`
