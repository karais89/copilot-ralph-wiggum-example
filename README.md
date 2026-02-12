# Ralph Wiggum Orchestration — Copilot Example

An AI-driven software development orchestration technique for **GitHub Copilot** (VS Code). Uses Copilot's `runSubagent` tool to autonomously implement projects through a coordinated system of orchestrator and subagent AI agents.

This repository serves two purposes:

1. **The RW orchestration template** — 8 reusable prompt files + structural docs that can be extracted and dropped into any project
2. **A working example** — A Todo CLI app built entirely by this technique (70+ commits, 20 tasks, zero manual coding)

## How It Works

```
rw-new-project  →  rw-plan  →  rw-run  →  rw-review  →  rw-feature  →  rw-plan  →  rw-run  →  rw-review  →  rw-archive
(신규/초기화+feature-seed) (bootstrap 계획) (구현 루프)      (수동 리뷰)    (기능별)      (계획)        (구현 루프)    (수동 리뷰)    (수동)
```

1. **`rw-new-project`** — Integrated bootstrap for new repos (`rw-init` + low-friction discovery + bootstrap feature seed generation)
2. **`rw-doctor`** — Optional standalone preflight diagnostic (rw-run always executes equivalent preflight once before loop)
3. **`rw-run`** — Runs implementation subagent loop
4. **`rw-review`** — Dispatches reviewer subagents to validate completed tasks in batch and writes `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE` (parallel only when all candidates are explicitly marked `Review Parallel: SAFE`, batch size 2)
5. **`rw-feature`** — Creates additional feature specification files
6. **`rw-plan`** — Breaks additional features into atomic tasks
7. **`rw-archive`** — Archives completed progress when it grows large

`rw-init` remains available as a scaffold-only fallback when you want non-interactive initialization.

### Runtime Policy

- Single `rw-run` policy (no lite/strict split).
- Review is manual and explicit via `rw-review` (subagent-backed batch review, deterministic parallel gate).
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

This copies 20 files into your project:

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
│   ├── rw-archive.prompt.md
│   ├── RW-INTERACTIVE-POLICY.md
│   └── RW-TARGET-ROOT-RESOLUTION.md
├── scripts/
│   ├── rw-resolve-target-root.sh
│   ├── rw-bootstrap-scaffold.sh
│   └── rw-target-registry.sh
└── .ai/                       # Structural files
    ├── CONTEXT.md             # Language policy & parser tokens
    ├── GUIDE.md               # Operational guide
    ├── features/
    │   ├── FEATURE-TEMPLATE.md
    │   └── README.md
    └── templates/
        ├── CONTEXT-BOOTSTRAP.md
        ├── PROJECT-CHARTER-TEMPLATE.md
        └── BOOTSTRAP-FEATURE-TEMPLATE.md
```

### Option 2: Manual Copy

Copy these paths from this repo into your project:
- `.github/prompts/*.prompt.md` (all 8 orchestration files)
- `.github/prompts/RW-INTERACTIVE-POLICY.md`
- `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md`
- `scripts/rw-resolve-target-root.sh`
- `scripts/rw-bootstrap-scaffold.sh`
- `scripts/rw-target-registry.sh`
- `.ai/CONTEXT.md`
- `.ai/GUIDE.md`
- `.ai/features/FEATURE-TEMPLATE.md`
- `.ai/features/README.md`
- `.ai/templates/CONTEXT-BOOTSTRAP.md`
- `.ai/templates/PROJECT-CHARTER-TEMPLATE.md`
- `.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md`

Then create empty directories: `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`

### After Extraction

1. Open your project in VS Code with GitHub Copilot
2. Open Copilot Chat and run **`rw-new-project`** — this performs scaffolding + lightweight project-direction discovery + bootstrap feature seed generation
   - `rw-new-project` uses `scripts/rw-bootstrap-scaffold.sh` as the default scaffold path.
   - `rw-new-project` refreshes target pointers automatically:
     - `workspace-root/.ai/runtime/rw-active-target-id.txt` -> `workspace-root`
     - `workspace-root/.ai/runtime/rw-targets/workspace-root.env` -> `TARGET_ROOT=<workspace-root>`
     - `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)
   - discovery is adaptive: ask intent first, then generate only high-impact follow-up questions from that intent (safe defaults for unanswered items)
3. Run **`rw-plan`** to generate bootstrap tasks from the seeded bootstrap feature
4. Run **`rw-run`** to implement tasks (auto preflight runs once before loop)
5. Run **`rw-review`** to validate the completed batch
6. If review leaves pending tasks, re-run **`rw-run`** and then run **`rw-review`** again
7. Run **`rw-feature`** to define additional product features
8. Run **`rw-plan`** to generate tasks for that feature
9. Run **`rw-run`**, then run **`rw-review`**
10. Optional: if you only need scaffold-only setup, run **`rw-init`** instead of step 2
   - `rw-init` refreshes the same target-pointer trio as `rw-new-project`

### Target Root Resolution

`rw-doctor`, `rw-run`, and `rw-review` resolve target root in this order:
1. `workspace-root/.ai/runtime/rw-active-target-id.txt`
2. `workspace-root/.ai/runtime/rw-targets/<target-id>.env` (`TARGET_ROOT=...`)
3. `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)

Shared resolver script:

```bash
./scripts/rw-resolve-target-root.sh "$(pwd)"
```

Resolver contract reference:
- `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md`

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
2. `rw-plan`
3. `rw-run`
4. `rw-review` (batch review after run)
5. `rw-feature`
6. `rw-plan`
7. `rw-run`

## Orchestration File Reference

### Prompts (`.github/prompts/`)

| Prompt | Purpose |
|---|---|
| [`rw-new-project`](.github/prompts/rw-new-project.prompt.md) | Integrated new-project init (`rw-init` + low-friction discovery + bootstrap feature seed generation) |
| [`rw-init`](.github/prompts/rw-init.prompt.md) | Scaffold-only fallback initialization (non-interactive) |
| [`rw-doctor`](.github/prompts/rw-doctor.prompt.md) | Standalone preflight check for top-level/runSubagent/git/.ai readiness and PASS-stamp write |
| [`rw-feature`](.github/prompts/rw-feature.prompt.md) | Create feature specification files |
| [`rw-plan`](.github/prompts/rw-plan.prompt.md) | Generate task breakdown for one READY_FOR_PLAN feature |
| [`rw-run`](.github/prompts/rw-run.prompt.md) | Orchestration loop for implementation subagent dispatch (target-root pointer file) |
| [`rw-review`](.github/prompts/rw-review.prompt.md) | Manual reviewer rules for subagent-backed batch validation of completed tasks |
| [`rw-archive`](.github/prompts/rw-archive.prompt.md) | Archive completed progress |

### Workspace (`.ai/`)

| File | Role |
|---|---|
| [`CONTEXT.md`](.ai/CONTEXT.md) | Language policy & machine-parseable tokens (read by every orchestration prompt `rw-*` at Step 0) |
| [`GUIDE.md`](.ai/GUIDE.md) | Operational guide for the RW workflow |
| [`PLAN.md`](.ai/PLAN.md) | Workspace metadata + append-only Feature Notes (`rw-new-project` creates/updates overview, `rw-plan` appends feature notes) |
| [`PROGRESS.md`](.ai/PROGRESS.md) | Task status & execution log (`rw-new-project` or `rw-init` creates skeleton, `rw-plan`/`rw-run` update entries) |
| `tasks/TASK-XX-*.md` | Individual task definitions (bootstrap and additional feature tasks are created by `rw-plan`) |
| `features/*.md` | Feature specifications (bootstrap feature may be created by `rw-new-project`; additional ones are created by `rw-feature`) |

### Safety Mechanisms

- **Step 0** — Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first; fails with `LANG_POLICY_MISSING` if missing
- **rw-doctor** — Standalone preflight diagnostic for top-level turn, runSubagent availability, git readiness, and `.ai` structure
- **RW_DOCTOR_AUTORUN_BEGIN / RW_DOCTOR_AUTORUN_PASS** — `rw-run` auto-preflight path that runs once before each loop execution
- **PAUSE.md** — Create `.ai/PAUSE.md` to halt the orchestration loop
- **ARCHIVE_LOCK** — Prevents concurrent archive operations
- **REVIEW-ESCALATE** — 3 consecutive review failures trigger escalation and require manual intervention
- **RW_ENV_UNSUPPORTED** — Explicit signal that autonomous mode is unavailable in the current environment
- **RW_TARGET_ROOT_INVALID** — Target root pointer is invalid (empty/non-absolute/missing path)
- **rw-run Dispatch Guard** — One subagent dispatch must complete exactly one locked task (`LOCKED_TASK_ID`)

### Next Command Contract

- Every operational prompt (`rw-*`) should end with one machine-readable line:
  - `NEXT_COMMAND=<prompt-name-or-action>`
- Follow `NEXT_COMMAND` as the primary next step signal for the workflow.

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
