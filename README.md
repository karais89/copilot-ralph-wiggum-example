# Todo CLI

A simple and elegant command-line Todo application built with Node.js and TypeScript. Manage your tasks directly from the terminal with intuitive commands.

## Features

- ✅ Add, list, complete, and delete todos
- 💾 Persistent storage using local JSON file
- 🎨 Clean, formatted output with status indicators
- ⚡ Fast and lightweight
- 🔍 ID prefix matching for easy task management
- 🛡️ Comprehensive error handling

## Tech Stack

- **Runtime**: Node.js (>=18)
- **Language**: TypeScript (strict mode)
- **CLI Framework**: Commander.js
- **Storage**: Local JSON file (`data/todos.json`)
- **Build Tool**: TypeScript Compiler (tsc)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd todo-cli
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Build the project**
   ```bash
   npm run build
   ```

4. **Link the CLI globally (optional)**
   ```bash
   npm link
   ```

   After linking, you can use the `todo` command from anywhere in your terminal.

## Usage

### Add a New Todo

Create a new todo item with a title:

```bash
todo add "Buy groceries"
```

Output:
```
✔ Added todo: "Buy groceries" (abc12345)
```

### List All Todos

Display all your todos with their status:

```bash
todo list
```

Example output:
```
[ ] abc12345  Buy groceries
[✓] def67890  Finish project documentation
[ ] ghi11223  Call dentist

Total: 3 todos
```

### Mark a Todo as Done

Toggle the completion status of a todo using its ID or ID prefix:

```bash
todo done abc12345
```

Or use just the prefix:
```bash
todo done abc
```

Output:
```
✔ Todo "Buy groceries" marked as completed
```

Running the same command again will toggle it back to incomplete:
```
✔ Todo "Buy groceries" marked as incomplete
```

### Delete a Todo

Permanently remove a todo using its ID or ID prefix:

```bash
todo delete abc12345
```

Or use just the prefix:
```bash
todo delete abc
```

Output:
```
✔ Deleted todo: "Buy groceries"
```

### Help

View available commands and options:

```bash
todo --help
```

Get help for a specific command:

```bash
todo add --help
todo list --help
todo done --help
todo delete --help
```

## Project Structure

```
src/
├── index.ts          # CLI entry point with Commander setup
├── commands/
│   ├── add.ts        # Add command handler
│   ├── list.ts       # List command handler
│   ├── update.ts     # Done/update command handler
│   └── delete.ts     # Delete command handler
├── models/
│   └── todo.ts       # Todo interface and type definitions
└── storage/
    └── json-store.ts # JSON file read/write operations
```

## Data Storage

Todos are stored in a local JSON file at `data/todos.json`. The file is automatically created when you add your first todo. Each todo has the following structure:

```typescript
interface Todo {
  id: string;          // Unique identifier (nanoid)
  title: string;       // Task description
  completed: boolean;  // Completion status
  createdAt: string;   // ISO 8601 timestamp
}
```

## Development

### Scripts

- `npm run build` - Compile TypeScript to JavaScript
- `npm start` - Run the compiled CLI
- `npm run dev` - Run the CLI in development mode with tsx

### Requirements

- Node.js version 18 or higher
- npm (comes with Node.js)

## About This Project

This project was built using the **Ralph Wiggum technique** — an orchestration pattern that leverages VS Code Copilot's `runSubagent` tool to autonomously implement projects through a coordinated system of orchestrator and subagent AI agents.

### How It Works

- **Orchestrator**: Manages the overall workflow, calling subagents sequentially
- **Subagents**: Each implements a single task independently
- **Progress Tracking**: All work tracked through `.ai/PROGRESS.md`

This approach provides:
- ⚡ **Cost efficiency**: 1 premium request for the entire project
- 🔄 **Context isolation**: Prevents "message too big" errors
- 📊 **Full traceability**: Every step logged and committed
- 🎯 **Autonomous execution**: Can run for hours without supervision

### Learn More

Want to use this technique for your own projects? Check out the guides:

- 📘 **[가이드](.ai/GUIDE.md)**: Ralph Wiggum 기법 사용법
- 🧭 **[Lite Plan](.github/prompts/rw-plan-lite.prompt.md)**: 단순/빠른 계획 생성용
- 🎭 **[Lite Orchestrator](.github/prompts/rw-run-lite.prompt.md)**: 단순/빠른 실행용
- 🧾 **[Strict Plan](.github/prompts/rw-plan-strict.prompt.md)**: 보수적 계획 생성용
- 🛡️ **[Strict Orchestrator](.github/prompts/rw-run-strict.prompt.md)**: reviewer + archive 포함
- 📋 **[플랜](.ai/PLAN.md)**: 프로젝트 PRD
- 📊 **[진행 추적](.ai/PROGRESS.md)**: 태스크 완료 상태

The `.ai/` folder contains all the planning documents, task breakdowns, and progress tracking used during this project's development.

## License

MIT

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
