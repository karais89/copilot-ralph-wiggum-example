# Todo CLI App — Product Requirements Document

## Overview

A command-line Todo application built with Node.js and TypeScript. Users can manage their tasks directly from the terminal with simple, intuitive commands.

## Feature Notes (append-only)

- 2026-02-07: [todo-cli-baseline] Initial baseline shipped (add/list/done/delete, JSON storage, error handling, docs). Related tasks: TASK-01~TASK-10.
- 2026-02-07: [stats-json-output] Add `todo stats` command with optional `--json` flag to display todo statistics. Text output shows total/completed/pending counts with visual formatting. JSON output returns machine-readable object with total, completed, pending, and completionRate (0-100). Related tasks: TASK-11~TASK-13.


## Tech Stack

- **Runtime**: Node.js (>=18)
- **Language**: TypeScript (strict mode)
- **CLI Framework**: Commander.js
- **Storage**: Local JSON file (`data/todos.json`)
- **Build**: `tsc` (TypeScript compiler)
- **Package Manager**: npm

## Data Model

```typescript
interface Todo {
  id: string;          // nanoid or UUID
  title: string;       // task description
  completed: boolean;  // completion status
  createdAt: string;   // ISO 8601 timestamp
}
```

## Functional Requirements

### Commands

| Command | Description | Example |
|---------|-------------|---------|
| `todo add <title>` | Add a new todo | `todo add "Buy groceries"` |
| `todo list` | List all todos | `todo list` |
| `todo done <id>` | Mark a todo as completed | `todo done abc123` |
| `todo delete <id>` | Delete a todo | `todo delete abc123` |

### Behavior

- `add`: Creates a new Todo with `completed: false`, auto-generates `id` and `createdAt`
- `list`: Displays all todos in a formatted table. Shows `[✓]` for completed, `[ ]` for pending
- `done`: Toggles the `completed` field of the specified todo
- `delete`: Permanently removes the todo from storage

## Non-Functional Requirements

- Graceful error handling for all commands (missing args, invalid ID, file errors)
- Help text via `todo --help` and `todo <command> --help`
- Zero external runtime dependencies beyond Commander.js and nanoid
- Works on macOS, Linux, and Windows

## Project Structure

```
src/
├── index.ts          # CLI entry point (Commander setup)
├── commands/
│   ├── add.ts        # add command handler
│   ├── list.ts       # list command handler
│   ├── update.ts     # done/update command handler
│   └── delete.ts     # delete command handler
├── models/
│   └── todo.ts       # Todo interface and type definitions
└── storage/
    └── json-store.ts # JSON file read/write operations
```

## Coding Conventions

- ESM modules (`"type": "module"` in package.json)
- Strict TypeScript (`"strict": true`)
- Conventional commits (e.g., `feat: add list command with table output`)
- No classes — prefer functions and modules
- All functions should have explicit return types
