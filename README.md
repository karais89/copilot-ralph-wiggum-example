# Ralph Wiggum Orchestration — Copilot Example

An AI-driven software development orchestration technique for **GitHub Copilot** (VS Code). Uses Copilot's `runSubagent` tool to autonomously implement projects through a coordinated system of orchestrator and subagent AI agents.

This repository serves two purposes:

1. **The RW orchestration template** — 9 orchestration prompts + smoke-test prompt/modules + structural docs that can be extracted and dropped into any project
2. **A working example** — A Todo CLI app built entirely by this technique (70+ commits, 20 tasks, zero manual coding)

## Quick Start (Minimal Mode)

If you are new to this project, use only this 4-step loop first:

1. Choose an entry prompt:
   - New/empty repository: `rw-new-project`
   - Existing codebase: `rw-onboard-project` then `rw-feature`
2. `rw-plan`
3. `rw-run`
4. `rw-review`

For the next feature, repeat:

`rw-feature -> rw-plan -> rw-run -> rw-review`

Use advanced/exception prompts only when needed:
- `rw-doctor`: preflight diagnostics only
- `rw-archive`: only when `rw-run` stops for archive thresholds
- `rw-init`: scaffold-only fallback
- `rw-smoke-test`: template/runtime validation

Optional helper commands:
- `./scripts/rw next`
- `./scripts/rw go`

## How It Works

```
rw-new-project  →  rw-plan  →  rw-run  →  rw-review  →  rw-feature  →  rw-plan  →  rw-run  →  rw-review
(신규/초기화+feature-seed) (bootstrap 계획) (구현 프롬프트) (리뷰 프롬프트) (기능별)      (계획)        (구현 프롬프트) (리뷰 프롬프트)
```

`rw-archive` is a manual exception step, only when archive thresholds stop `rw-run`.

1. **`rw-new-project`** — Integrated bootstrap for new/empty repos (`rw-init` + low-friction discovery + bootstrap feature seed generation)
2. **`rw-onboard-project`** — Existing-codebase onboarding (language-agnostic codebase signal detection + snapshot + handoff to `rw-feature`)
3. **`rw-doctor`** — Optional standalone preflight diagnostic (rw-run always executes equivalent preflight once before loop)
4. **`rw-run`** — Runs implementation subagent loop
5. **`rw-review`** — Dispatches reviewer subagents to validate completed tasks in batch, writes `REVIEW_OK` / `REVIEW_FAIL` / `REVIEW-ESCALATE`, emits `REVIEW_STATUS=<APPROVED|NEEDS_REVISION|FAILED>`, and creates one review phase note in `.ai/notes/` (parallel only when all candidates are explicitly marked `Review Parallel: SAFE`, batch size 2)
6. **`rw-feature`** — Creates additional feature specification files
7. **`rw-plan`** — Breaks additional features into atomic tasks
8. **`rw-archive`** — Archives completed progress when it grows large

`rw-init` remains available as a scaffold-only fallback when you want non-interactive initialization.

### Runtime Policy

- Single `rw-run` policy (no lite/strict split).
- Review is manual and explicit via `rw-review` (subagent-backed batch review, deterministic parallel gate).
- Archive threshold is hard-stop; run resumes after manual `rw-archive`.
- `rw-run` preflight uses doctor-stamp cache first (same target + 10-minute TTL), then falls back to full preflight on cache miss.

### Branch Strategy (github-flow)

- Keep `main` always releasable.
- Do all work on short-lived branches, not directly on `main`.
- Recommended branch naming: `codex/<short-topic>`.
- Typical flow:
  1. Update `main`
  2. Create `codex/<short-topic>`
  3. Commit on branch
  4. Open PR and pass checks
  5. Squash merge to `main`
  6. Delete merged branch

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

# Optional: scaffold default user-doc language as English
# RW_DOC_LANG=en ./scripts/rw-bootstrap-scaffold.sh ~/your-project
```

This copies the full RW template bundle (prompts, smoke modules, scripts, and `.ai` structural files) into your project:

```
your-project/
├── .github/prompts/           # 9 orchestration prompts + rw-smoke-test
│   ├── rw-init.prompt.md
│   ├── rw-new-project.prompt.md
│   ├── rw-onboard-project.prompt.md
│   ├── rw-doctor.prompt.md
│   ├── rw-feature.prompt.md
│   ├── rw-plan.prompt.md
│   ├── rw-run.prompt.md
│   ├── rw-review.prompt.md
│   ├── rw-archive.prompt.md
│   ├── rw-smoke-test.prompt.md
│   ├── RW-INTERACTIVE-POLICY.md
│   └── RW-TARGET-ROOT-RESOLUTION.md
├── scripts/
│   ├── rw-resolve-target-root.sh
│   ├── rw-bootstrap-scaffold.sh
│   ├── rw-target-registry.sh
│   ├── rw
│   ├── validate-smoke-result.sh
│   └── check-prompts.mjs
└── .ai/                       # Structural files
    ├── CONTEXT.md             # Language policy & parser tokens
    ├── GUIDE.md               # Operational guide
    ├── features/
    │   ├── FEATURE-TEMPLATE.md
    │   └── README.md
    └── templates/
        ├── CONTEXT-BOOTSTRAP.md
        ├── PROJECT-CHARTER-TEMPLATE.md
        ├── BOOTSTRAP-FEATURE-TEMPLATE.md
        └── SMOKE-RESULT-SCHEMA.json
```

### Option 2: Manual Copy

Copy these paths from this repo into your project:
- `.github/prompts/*.prompt.md` (all `rw-*.prompt.md` files, including `rw-smoke-test.prompt.md`)
- `.github/prompts/RW-INTERACTIVE-POLICY.md`
- `.github/prompts/RW-TARGET-ROOT-RESOLUTION.md`
- `scripts/rw-resolve-target-root.sh`
- `scripts/rw-bootstrap-scaffold.sh`
- `scripts/rw-target-registry.sh`
- `scripts/rw`
- `scripts/validate-smoke-result.sh`
- `scripts/check-prompts.mjs`
- `.ai/CONTEXT.md`
- `.ai/GUIDE.md`
- `.ai/features/FEATURE-TEMPLATE.md`
- `.ai/features/README.md`
- `.ai/templates/CONTEXT-BOOTSTRAP.md`
- `.ai/templates/PROJECT-CHARTER-TEMPLATE.md`
- `.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md`
- `.ai/templates/SMOKE-RESULT-SCHEMA.json`

Then create empty directories: `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`

### After Extraction

1. Open your project in VS Code with GitHub Copilot
2. Open Copilot Chat and choose one entry prompt:
   - **`rw-new-project`** for new/empty repos (scaffolding + lightweight project-direction discovery + bootstrap feature seed generation)
   - **`rw-onboard-project`** for existing codebases (language-agnostic codebase detection + `PLAN` snapshot + handoff to `rw-feature`)
   - `rw-new-project` uses `scripts/rw-bootstrap-scaffold.sh` as the default scaffold path.
   - Entry prompts refresh target pointers automatically:
     - `workspace-root/.ai/runtime/rw-active-target-id.txt` -> `workspace-root`
     - `workspace-root/.ai/runtime/rw-targets/workspace-root.env` -> `TARGET_ROOT=<workspace-root>`
     - `workspace-root/.ai/runtime/rw-active-target-root.txt` (legacy fallback)
   - `rw-new-project` discovery is adaptive: ask intent first, then generate only high-impact follow-up questions from that intent (safe defaults for unanswered items)
3. New/empty path only: run **`rw-plan`** to generate bootstrap tasks from the seeded bootstrap feature
   - For quick smoke tests, set `Planning Profile: FAST_TEST` in the target feature file before running `rw-plan` (generates 2-3 tasks).
4. Run **`rw-run`** to implement tasks (auto preflight runs once before loop)
5. Run **`rw-review`** to validate the completed batch
6. If review leaves pending tasks, re-run **`rw-run`** and then run **`rw-review`** again
7. Run **`rw-feature`** to define additional product features (or first feature after `rw-onboard-project`)
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

### Workflow Helper Commands

Use the lightweight helper script to check current state and next action:

```bash
./scripts/rw status
./scripts/rw next
./scripts/rw go
```

Optional workspace-root override:

```bash
./scripts/rw status /absolute/path/to/workspace-root
./scripts/rw next /absolute/path/to/workspace-root
./scripts/rw go /absolute/path/to/workspace-root
```

Single-command prompt aliases:

```bash
./scripts/rw new
./scripts/rw onboard
./scripts/rw init
./scripts/rw doctor
./scripts/rw feature
./scripts/rw plan
./scripts/rw run
./scripts/rw review
./scripts/rw archive
./scripts/rw smoke
```

`rw next` prints machine-readable recommendation tokens:
- `NEXT_COMMAND=<rw-new-project|rw-onboard-project|rw-feature|rw-plan|rw-run|rw-review|rw-archive>`
- `NEXT_REASON=<reason-token>`

`rw go` resolves `NEXT_COMMAND` and prints mapped prompt dispatch info:
- `COPILOT_PROMPT=<rw-*.prompt target>`
- `PROMPT_FILE=<workspace/.github/prompts/...>`

### Verification Guidance

This branch intentionally removes bundled Copilot test prompts (`copilot-rw-*`) to keep operations minimal.
For verification, run the core flow directly in Copilot Chat:

1. `rw-new-project` (new/empty) or `rw-onboard-project -> rw-feature` (existing)
2. `rw-plan`
3. `rw-run`
4. `rw-review` (batch review after run)
5. `rw-feature`
6. `rw-plan`
7. `rw-run`
8. `rw-review`

### Default Operation Path (Single Path)

- Default path (always start here):
  - `rw-new-project -> rw-plan -> rw-run -> rw-review`
- Existing codebase start path:
  - `rw-onboard-project -> rw-feature -> rw-plan -> rw-run -> rw-review`
- Continue feature work with:
  - `rw-feature -> rw-plan -> rw-run -> rw-review`
- Use exception prompts only when needed:
  - `rw-doctor`: only when checking preflight blockers explicitly
  - `rw-archive`: only when archive thresholds stop `rw-run`

### Failure Triage (3 Groups)

- `ENV` (environment/tooling/root resolution)
  - Examples: `RW_ENV_UNSUPPORTED`, `TOP_LEVEL_REQUIRED`, `RW_TARGET_ROOT_INVALID`, `GIT_REPO_MISSING`
  - Action: fix environment/root/tool availability first, then rerun same command.
- `FLOW` (workflow order/state mismatch)
  - Examples: `FEATURE_NOT_READY`, `FEATURE_FILE_MISSING`, `RW_TASK_DEPENDENCY_BLOCKED`, `REVIEW_BLOCKED`
  - Action: follow `NEXT_COMMAND` and correct status/order before rerun.
- `DATA` (workspace file readability/format)
  - Examples: `LANG_POLICY_MISSING`, `RW_CORE_FILE_UNREADABLE`
  - Action: restore required files/headers/tokens, then rerun.

### Fast Test Default

- For test runs, treat `Planning Profile: FAST_TEST` as the default.
- Before `rw-plan`, set this line in the selected feature file:
  - `Planning Profile: FAST_TEST`
- This keeps planning output in the 2-3 task range for quick validation cycles.

## Orchestration File Reference

### Prompts (`.github/prompts/`)

| Prompt | Purpose |
|---|---|
| [`rw-new-project`](.github/prompts/rw-new-project.prompt.md) | Integrated new-project init (`rw-init` + low-friction discovery + bootstrap feature seed generation) |
| [`rw-onboard-project`](.github/prompts/rw-onboard-project.prompt.md) | Existing-codebase onboarding (language-agnostic codebase detection + `PLAN` snapshot + handoff to `rw-feature`) |
| [`rw-init`](.github/prompts/rw-init.prompt.md) | Scaffold-only fallback initialization (non-interactive) |
| [`rw-doctor`](.github/prompts/rw-doctor.prompt.md) | Standalone preflight check for top-level/runSubagent/git/.ai readiness and PASS-stamp write |
| [`rw-feature`](.github/prompts/rw-feature.prompt.md) | Create feature specification files |
| [`rw-plan`](.github/prompts/rw-plan.prompt.md) | Generate task breakdown for one READY_FOR_PLAN feature |
| [`rw-run`](.github/prompts/rw-run.prompt.md) | Orchestration loop for implementation subagent dispatch (target-root pointer file) |
| [`rw-review`](.github/prompts/rw-review.prompt.md) | Manual reviewer rules for subagent-backed batch validation, normalized `REVIEW_STATUS`, and one review phase note artifact |
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
테스트 문장입니다.
