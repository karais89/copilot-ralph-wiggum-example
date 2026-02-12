# Ralph Wiggum Orchestration — Copilot Example

An AI-driven software development orchestration technique for **GitHub Copilot** (VS Code). Uses Copilot's `runSubagent` tool to autonomously implement projects through a coordinated system of orchestrator and subagent AI agents.

This repository serves two purposes:

1. **The RW orchestration template** — 8 reusable prompt files + structural docs that can be extracted and dropped into any project
2. **A working example** — A Todo CLI app built entirely by this technique (70+ commits, 20 tasks, zero manual coding)

## How It Works

```
rw-new-project  →  rw-doctor  →  rw-run  →  rw-review  →  rw-feature  →  rw-plan  →  rw-run  →  rw-review  →  rw-archive
(신규/초기화+bootstrap) (사전점검)     (구현 루프)      (수동 리뷰)    (기능별)      (계획)        (구현 루프)    (수동 리뷰)    (수동)
```

1. **`rw-new-project`** — Integrated bootstrap for new repos (`rw-init` + discovery + bootstrap feature/task decomposition in one run)
2. **`rw-doctor`** — Validates top-level/runSubagent/git/.ai preflight before autonomous runs (supports target-root pointer file)
3. **`rw-run`** — Runs implementation subagent loop
4. **`rw-review`** — Reviews latest completed task and writes `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`
5. **`rw-feature`** — Creates additional feature specification files
6. **`rw-plan`** — Breaks additional features into atomic tasks
7. **`rw-archive`** — Archives completed progress when it grows large

`rw-init` remains available as a scaffold-only fallback when you want non-interactive initialization.

### Runtime Policy

- Single `rw-run` policy (no lite/strict split).
- Review is manual and explicit via `rw-review`.
- Archive threshold is hard-stop; run resumes after manual `rw-archive`.

### Key Benefits

- **Cost efficiency** — 1 premium request can drive an entire project
- **Context isolation** — Each subagent gets a fresh context, preventing "message too big" errors
- **Full traceability** — Every step logged in PROGRESS.md and committed
- **Autonomous execution** — Can run for hours without supervision
- **Language/toolchain agnostic** — Prompts target repository-defined commands and structure (works for web, app, and game/Unity projects)

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
│   ├── rw-doctor.prompt.md
│   ├── rw-feature.prompt.md
│   ├── rw-plan.prompt.md
│   ├── rw-run.prompt.md
│   ├── rw-review.prompt.md
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
- `.github/prompts/*.prompt.md` (all 8 orchestration files)
- `.ai/CONTEXT.md`
- `.ai/GUIDE.md`
- `.ai/features/FEATURE-TEMPLATE.md`
- `.ai/features/README.md`

Then create empty directories: `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`

### After Extraction

1. Open your project in VS Code with GitHub Copilot
2. Open Copilot Chat and run **`rw-new-project`** — this performs scaffolding + project-direction discovery + bootstrap feature/task generation
   - `rw-new-project` refreshes target pointers automatically:
     - `workspace-root/.ai/runtime/rw-active-target-id.txt` -> `workspace-root`
     - `workspace-root/.ai/runtime/rw-targets/workspace-root.env` -> `TARGET_ROOT=<workspace-root>`
     - `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)
3. Run **`rw-doctor`** before autonomous execution
4. Run **`rw-run`** to implement tasks
5. If `rw-run` prints `REVIEW_REQUIRED TASK-XX`, run **`rw-review`**
6. Re-run **`rw-run`** and repeat step 5 until the current batch is complete
7. Run **`rw-feature`** to define additional product features
8. Run **`rw-plan`** to generate tasks for that feature
9. Run **`rw-doctor`** again before the next autonomous execution
10. Run **`rw-run`** and continue with `rw-review` when required
11. Optional: if you only need scaffold-only setup, run **`rw-init`** instead of step 2
   - `rw-init` refreshes the same target-pointer trio as `rw-new-project`

### Target Root Resolution

`rw-doctor` and `rw-run` resolve target root in this order:
1. `workspace-root/.ai/runtime/rw-active-target-id.txt`
2. `workspace-root/.ai/runtime/rw-targets/<target-id>.env` (`TARGET_ROOT=...`)
3. `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)

Manual target switch from workspace root:

```bash
./scripts/rw-target-registry.sh set-active "$(pwd)" my-project "/absolute/path/to/project"
./scripts/rw-target-registry.sh resolve-active "$(pwd)"
```

If VS Code workspace root and actual target project root are different, update active target id + registry first, then keep legacy pointer synchronized for compatibility.

### Verification Guidance

This branch intentionally removes bundled Copilot test prompts (`copilot-rw-*`) to keep operations minimal.
For verification, run the core flow directly in Copilot Chat:

1. `rw-new-project`
2. `rw-run`
3. `rw-review` (when `REVIEW_REQUIRED TASK-XX` appears)
4. `rw-feature`
5. `rw-plan`
6. `rw-run`

## Orchestration File Reference

### Prompts (`.github/prompts/`)

| Prompt | Purpose |
|---|---|
| [`rw-new-project`](.github/prompts/rw-new-project.prompt.md) | Integrated new-project init (`rw-init` + discovery + bootstrap feature/task decomposition) |
| [`rw-init`](.github/prompts/rw-init.prompt.md) | Scaffold-only fallback initialization (non-interactive) |
| [`rw-doctor`](.github/prompts/rw-doctor.prompt.md) | Preflight check for top-level/runSubagent/git/.ai readiness before autonomous runs (target-root pointer file) |
| [`rw-feature`](.github/prompts/rw-feature.prompt.md) | Create feature specification files |
| [`rw-plan`](.github/prompts/rw-plan.prompt.md) | Generate task breakdown for one READY_FOR_PLAN feature |
| [`rw-run`](.github/prompts/rw-run.prompt.md) | Orchestration loop for implementation subagent dispatch (target-root pointer file) |
| [`rw-review`](.github/prompts/rw-review.prompt.md) | Manual reviewer rules for validating one latest completed task |
| [`rw-archive`](.github/prompts/rw-archive.prompt.md) | Archive completed progress |

### Workspace (`.ai/`)

| File | Role |
|---|---|
| [`CONTEXT.md`](.ai/CONTEXT.md) | Language policy & machine-parseable tokens (read by every orchestration prompt `rw-*` at Step 0) |
| [`GUIDE.md`](.ai/GUIDE.md) | Operational guide for the RW workflow |
| [`PLAN.md`](.ai/PLAN.md) | Workspace metadata + append-only Feature Notes (`rw-new-project` creates/updates overview, `rw-plan` appends feature notes) |
| [`PROGRESS.md`](.ai/PROGRESS.md) | Task status & execution log (`rw-new-project` or `rw-init` creates skeleton, `rw-plan`/`rw-run` update entries) |
| `tasks/TASK-XX-*.md` | Individual task definitions (`rw-new-project` creates bootstrap `TASK-01+`; additional feature tasks are created by `rw-plan`) |
| `features/*.md` | Feature specifications (bootstrap feature may be created by `rw-new-project`; additional ones are created by `rw-feature`) |

### Safety Mechanisms

- **Step 0** — Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first; fails with `LANG_POLICY_MISSING` if missing
- **rw-doctor** — Preflight gate for top-level turn, runSubagent availability, git readiness, and `.ai` structure
- **PAUSE.md** — Create `.ai/PAUSE.md` to halt the orchestration loop
- **ARCHIVE_LOCK** — Prevents concurrent archive operations
- **REVIEW-ESCALATE** — 3 consecutive review failures trigger escalation and require manual intervention
- **RW_ENV_UNSUPPORTED** — Explicit signal that autonomous mode is unavailable in the current environment
- **RW_TARGET_ROOT_INVALID** — Target root pointer is invalid (empty/non-absolute/missing path)

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
