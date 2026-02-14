---
name: rw-onboard-project
description: "Onboard an existing codebase into RW: scaffold + language-agnostic codebase snapshot + rw-feature handoff"
agent: agent
argument-hint: "Optional one-line context for the existing project."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Use this prompt for an existing, already-implemented repository.
- Scope: scaffold/repair `.ai` baseline and capture a current codebase snapshot.
- Do not create bootstrap feature seeds or decompose tasks.
- Default handoff is `rw-feature`.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If missing, create it from `.ai/templates/CONTEXT-BOOTSTRAP.md` when available; otherwise create a minimal bootstrap context file.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Input:
- `onboardSummary` (optional)

Rules:
- Do not edit product code.
- This prompt must run in a top-level Copilot Chat turn.
  - If not top-level, output `TOP_LEVEL_REQUIRED` and stop.
- Keep machine tokens unchanged (`Task Status`, `Log`, `pending`, `Status`, `READY_FOR_PLAN`, `PLANNED`).
- Write user-facing prose in language resolved from `.ai/CONTEXT.md` (default Korean if ambiguous).
- Do not create or modify `.ai/features/*.md` in this prompt.
- Do not create commits in this prompt.
- Language-agnostic detection only:
  - Do not rely on natural-language keywords from README or comments.
  - Use file presence, file structure, extensions, and executable command signals.

Workflow:
1) Pre-scan task baseline before scaffold:
   - Count existing `TASK-*.md` files in `.ai/tasks/` as `TASK_COUNT_BEFORE`.
   - Record whether `TASK-01-bootstrap-workspace.md` existed before scaffold.

2) Scaffold baseline via shared script (required):
   - Run `scripts/rw-bootstrap-scaffold.sh "<workspace-root-absolute-path>"`.
   - If script is missing or fails, stop immediately and output:
     - first line exactly: `RW_SCAFFOLD_FAILED`
     - second line: `<short reason>`
     - third line: `Fix scaffold script/runtime and rerun rw-onboard-project.`

3) Detect existing-codebase signals (language-agnostic):
   - Compute these signals from repository files (excluding `.git`, `.ai`, `node_modules`, `dist`, `build`, `vendor`, `.next`, `coverage`):
     - `MANIFEST_SIGNAL`: at least one build/package manifest exists.
       - Examples: `package.json`, `pnpm-workspace.yaml`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `build.gradle.kts`, `Gemfile`, `composer.json`, `deno.json`.
     - `SOURCE_SIGNAL`: at least 3 product-source files exist under common source roots (`src`, `app`, `lib`, `server`, `backend`, `frontend`, `cmd`, `internal`, `services`, `packages/*/src`).
       - Use extension-based detection only (for example: `js`, `ts`, `jsx`, `tsx`, `py`, `go`, `rs`, `java`, `kt`, `rb`, `php`, `cs`, `swift`, `c`, `cc`, `cpp`).
     - `BUILD_OR_TEST_SIGNAL`: at least one executable build/test config exists.
       - Examples: `Makefile`, `Dockerfile`, `docker-compose.yml`, `pytest.ini`, `tox.ini`, `vite.config.*`, `webpack.config.*`, `tsconfig.json`.
     - `README_SIGNAL`: `README.md` exists and is non-trivial (>= 200 characters), regardless of language.
   - Set `CODEBASE_SIGNAL_COUNT` to the number of true signals.
   - Set `CONTEXT_MODE`:
     - `EXISTING_READY` if `SOURCE_SIGNAL=true` OR `CODEBASE_SIGNAL_COUNT>=2`
     - `EMPTY_OR_TEMPLATE` otherwise

4) If `CONTEXT_MODE=EMPTY_OR_TEMPLATE`:
   - Keep scaffolded baseline as-is.
   - Do not write existing-project snapshot content.
   - Output:
     - `ONBOARD_RESULT=blocked`
     - `CONTEXT_MODE=EMPTY_OR_TEMPLATE`
     - `TASK01_RESULT=kept`
     - `SNAPSHOT_RESULT=skipped`
     - `VERIFICATION_BASELINE=none`
     - `NEXT_COMMAND=rw-new-project`
   - Stop.

5) Build current codebase snapshot (existing project mode):
   - Gather only observable facts:
     - inferred project name (directory name or manifest name)
     - detected stack/runtime signals from manifests/extensions
     - key top-level source/config paths
     - one canonical verification baseline command when discoverable from ecosystem signals
       - Node: prefer `npm run build` when build script exists, else `npm test`, else `npm run test`
       - Python: `pytest -q`
       - Go: `go test ./...`
       - Rust: `cargo test`
       - Java/Gradle: `./gradlew test`
       - Java/Maven: `mvn test`
       - Unknown: `none`
     - unresolved assumptions (if any)
   - If `onboardSummary` is provided, use it only as supplemental context (never override file-based facts).

6) Update `PLAN.md` with strict boundaries:
   - If missing, create:
     - title (`# <project-name>`)
     - `## Overview` with 3~6 concise lines from detected facts
     - `## Current Codebase Snapshot`
     - `## Feature Notes (append-only)`
   - If existing:
     - keep all existing content unchanged
     - ensure `## Current Codebase Snapshot` section exists
     - append one dated snapshot entry under that section (do not rewrite prior entries)
     - ensure `## Feature Notes (append-only)` exists
   - Snapshot entry must include:
     - `- Captured At: <YYYY-MM-DD>`
     - `- Codebase Signals: <short list>`
     - `- Core Stack: <short list>`
     - `- Key Paths: <short list>`
     - `- Verification Baseline: <command|none>`

7) Remove scaffold-only bootstrap task when safe:
   - Re-count tasks as `TASK_COUNT_AFTER`.
   - If all are true:
     - `TASK_COUNT_BEFORE=0`
     - `TASK_COUNT_AFTER=1`
     - the only task file is `.ai/tasks/TASK-01-bootstrap-workspace.md`
     then:
       - delete `.ai/tasks/TASK-01-bootstrap-workspace.md`
       - remove `TASK-01` row from `.ai/PROGRESS.md` Task Status when present
       - append one log line in `.ai/PROGRESS.md`: `- **YYYY-MM-DD** — Existing-project onboarding removed bootstrap TASK-01.`
       - set `TASK01_RESULT=removed`
   - Otherwise set `TASK01_RESULT=kept`.
   - Never delete any non-bootstrap task.

8) Decide next command:
   - set `NEXT_COMMAND=rw-feature`

Output format (machine-friendly, fixed keys):
- `ONBOARD_RESULT=<created|updated|blocked>`
- `CONTEXT_MODE=<EXISTING_READY|EMPTY_OR_TEMPLATE>`
- `CODEBASE_SIGNAL_COUNT=<n>`
- `SNAPSHOT_RESULT=<created|updated|appended|skipped>`
- `TASK01_RESULT=<removed|kept>`
- `VERIFICATION_BASELINE=<command|none>`
- `NEXT_COMMAND=<rw-feature|rw-new-project>`
