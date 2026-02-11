# Ralph Wiggum Orchestration — Copilot Example

An AI-driven software development orchestration technique for **GitHub Copilot** (VS Code). Uses Copilot's `runSubagent` tool to autonomously implement projects through a coordinated system of orchestrator and subagent AI agents.

This repository serves two purposes:

1. **The RW orchestration template** — 8 reusable prompt files + structural docs that can be extracted and dropped into any project
2. **A working example** — A Todo CLI app built entirely by this technique (70+ commits, 20 tasks, zero manual coding)

## How It Works

```
rw-new-project  →  rw-run-*  →  rw-feature  →  rw-plan-*  →  rw-run-*  →  rw-archive
(신규/초기화+bootstrap) (bootstrap 구현) (기능별)      (계획)        (자동 루프)    (수동)
```

1. **`rw-new-project`** — Integrated bootstrap for new repos (`rw-init` + discovery + bootstrap feature/task decomposition in one run)
2. **`rw-run-lite` / `rw-run-strict`** — Implements bootstrap tasks first
3. **`rw-feature`** — Creates additional feature specification files
4. **`rw-plan-lite` / `rw-plan-strict`** — Breaks additional features into atomic tasks
5. **`rw-run-lite` / `rw-run-strict`** — Continues autonomous implementation loop
6. **`rw-archive`** — Archives completed progress when it grows large

`rw-init` remains available as a scaffold-only fallback when you want non-interactive initialization.

### Two Modes

| | Lite | Strict |
|---|---|---|
| Reviewer subagent | No | Yes (validates each task) |
| Review failure tracking | N/A | `REVIEW_FAIL` (1/3, 2/3) → `REVIEW-ESCALATE` (3/3) |
| Archive on threshold | Warning only (continues) | Hard stop (manual archive required) |
| Best for | Small/fast features | Critical/complex features |

### Key Benefits

- **Cost efficiency** — 1 premium request can drive an entire project
- **Context isolation** — Each subagent gets a fresh context, preventing "message too big" errors
- **Full traceability** — Every step logged in PROGRESS.md and committed
- **Autonomous execution** — Can run for hours without supervision
- **Language/toolchain agnostic** — Prompts contain zero hardcoded language or framework references

## Use in Your Own Project

### Option 1: Extract Template (Recommended)

```bash
git clone https://github.com/karais89/copilot-ralph-wiggum-example.git
cd copilot-ralph-wiggum-example

# Extract only the RW template files into your project
./scripts/extract-template.sh ~/your-project
```

This copies 12 files into your project:

```
your-project/
├── .github/prompts/           # 8 orchestration prompts
│   ├── rw-init.prompt.md
│   ├── rw-new-project.prompt.md
│   ├── rw-feature.prompt.md
│   ├── rw-plan-lite.prompt.md
│   ├── rw-plan-strict.prompt.md
│   ├── rw-run-lite.prompt.md
│   ├── rw-run-strict.prompt.md
│   └── rw-archive.prompt.md
└── .ai/                       # Structural files
    ├── CONTEXT.md             # Language policy & parser tokens
    ├── GUIDE.md               # Operational guide
    └── features/
        ├── FEATURE-TEMPLATE.md
        └── README.md
```

### Option 2: Manual Copy

Copy these paths from this repo into your project:
- `.github/prompts/*.prompt.md` (all 8 files)
- `.ai/CONTEXT.md`
- `.ai/GUIDE.md`
- `.ai/features/FEATURE-TEMPLATE.md`
- `.ai/features/README.md`

Then create empty directories: `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`

### After Extraction

1. Open your project in VS Code with GitHub Copilot
2. Open Copilot Chat and run **`rw-new-project`** — this performs scaffolding + project-direction discovery + bootstrap feature/task generation
3. Run **`rw-run-lite`** (or `rw-run-strict`) to implement bootstrap tasks
4. Run **`rw-feature`** to define additional product features
5. Run **`rw-plan-lite`** (or `rw-plan-strict`) to generate tasks for that feature
6. Run **`rw-run-lite`** (or `rw-run-strict`) to continue the autonomous loop
7. Optional: if you only need scaffold-only setup, run **`rw-init`** instead of step 2

## Orchestration File Reference

### Prompts (`.github/prompts/`)

| Prompt | Purpose |
|---|---|
| [`rw-new-project`](.github/prompts/rw-new-project.prompt.md) | Integrated new-project init (`rw-init` + discovery + bootstrap feature/task decomposition) |
| [`rw-init`](.github/prompts/rw-init.prompt.md) | Scaffold-only fallback initialization (non-interactive) |
| [`rw-feature`](.github/prompts/rw-feature.prompt.md) | Create feature specification files |
| [`rw-plan-lite`](.github/prompts/rw-plan-lite.prompt.md) | Generate task breakdown (Lite mode) |
| [`rw-plan-strict`](.github/prompts/rw-plan-strict.prompt.md) | Generate task breakdown (Strict mode) |
| [`rw-run-lite`](.github/prompts/rw-run-lite.prompt.md) | Orchestration loop (Lite mode) |
| [`rw-run-strict`](.github/prompts/rw-run-strict.prompt.md) | Orchestration loop + reviewer (Strict mode) |
| [`rw-archive`](.github/prompts/rw-archive.prompt.md) | Archive completed progress |

### Workspace (`.ai/`)

| File | Role |
|---|---|
| [`CONTEXT.md`](.ai/CONTEXT.md) | Language policy & machine-parseable tokens (read by every prompt at Step 0) |
| [`GUIDE.md`](.ai/GUIDE.md) | Operational guide for the RW workflow |
| [`PLAN.md`](.ai/PLAN.md) | Workspace metadata + append-only Feature Notes (`rw-new-project` creates/updates overview, `rw-plan-*` appends feature notes) |
| [`PROGRESS.md`](.ai/PROGRESS.md) | Task status & execution log (`rw-new-project` or `rw-init` creates skeleton, `rw-plan-*`/`rw-run-*` update entries) |
| `tasks/TASK-XX-*.md` | Individual task definitions (`rw-new-project` creates bootstrap `TASK-01+`; additional feature tasks are created by `rw-plan-*`) |
| `features/*.md` | Feature specifications (bootstrap feature may be created by `rw-new-project`; additional ones are created by `rw-feature`) |

### Safety Mechanisms

- **Step 0** — Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first; fails with `LANG_POLICY_MISSING` if missing
- **PAUSE.md** — Create `.ai/PAUSE.md` to halt the orchestration loop
- **ARCHIVE_LOCK** — Prevents concurrent archive operations
- **REVIEW-ESCALATE** — (Strict mode) 3 consecutive review failures trigger escalation and halt
- **MANUAL_FALLBACK_REQUIRED** — Graceful degradation when `runSubagent` is unavailable

## Example: Todo CLI

This repository includes a complete Todo CLI app as a working example of the RW technique in action. The entire app was built autonomously — from project init to error handling to documentation — across 20 tasks and 70+ commits.

### Quick Start (Example App)

```bash
git clone https://github.com/karais89/copilot-ralph-wiggum-example.git
cd copilot-ralph-wiggum-example
npm install
npm run build
npm link    # optional: enables global 'todo' command
```

### Commands

```bash
todo add "Buy groceries"     # Add a new todo
todo list                    # List all todos
todo done <id>               # Toggle completion
todo delete <id>             # Delete a todo
todo stats                   # Show statistics
todo stats --json            # Machine-readable JSON output
todo clear                   # Remove completed todos
```

### Tech Stack

- Node.js (>=18), TypeScript (strict), Commander.js, nanoid
- Local JSON storage (`data/todos.json`)
- Vitest for testing

### Development Scripts

```bash
npm run build   # Compile TypeScript
npm run dev     # Run with tsx (dev mode)
npm test        # Run tests
```

## Requirements

- **VS Code** with **GitHub Copilot** (Copilot Chat with `runSubagent` support)
- For the example Todo CLI: Node.js >= 18

## License

MIT

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
