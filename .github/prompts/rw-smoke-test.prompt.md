---
name: rw-smoke-test
description: "E2E smoke test: dispatches subagents to run the full RW pipeline (new-project → plan → run → review → feature → plan → run → review) on a temp project and validates results"
agent: agent
argument-hint: "Optional: absolute path to workspace root. Default: creates temp dir under /tmp."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Automated end-to-end smoke test for the RW orchestration pipeline.
- Creates a temporary project, then dispatches subagents for each RW step.
- Validates file contracts, state transitions, and build results between steps.
- Outputs `SMOKE_TEST_PASS` on success, `SMOKE_TEST_FAIL <phase>` on failure.

Modular layout:
- Common contract: `.github/prompts/smoke/SMOKE-CONTRACT.md`
- Phase specs:
  - `.github/prompts/smoke/phases/phase-01-new-project.md`
  - `.github/prompts/smoke/phases/phase-02-plan.md`
  - `.github/prompts/smoke/phases/phase-03-run.md`
  - `.github/prompts/smoke/phases/phase-04-review.md`
  - `.github/prompts/smoke/phases/phase-05-feature.md`
  - `.github/prompts/smoke/phases/phase-06-plan-2.md`
  - `.github/prompts/smoke/phases/phase-07-run-2.md`
  - `.github/prompts/smoke/phases/phase-08-review-2.md`

Execution rules:
1) Resolve `PROMPT_ROOT` as the absolute directory containing this file (`.github/prompts`).
2) Read and apply `"$PROMPT_ROOT/smoke/SMOKE-CONTRACT.md"` first.
3) If any referenced spec/template file is missing, print `SMOKE_TEST_FAIL setup: missing spec file <path>` and stop.
4) Execute `Setup`, then execute phase files 01-08 in order.
5) Follow all tokens, gate checks, and stop conditions from the contract/phase docs exactly.

## Setup

1) Determine `WORKSPACE_ROOT`:
   - If user provided an argument, use that as `WORKSPACE_ROOT`.
   - Otherwise, create a temp directory: run `mktemp -d /tmp/rw-smoke-XXXXXX` and use the result.
2) Determine `TEMPLATE_SOURCE`:
   - The current VS Code workspace root (where this prompt file lives).
3) Run `"$TEMPLATE_SOURCE/scripts/extract-template.sh" "$WORKSPACE_ROOT"`.
   - If it fails, print `SMOKE_TEST_FAIL setup: extract-template.sh failed` and stop.
4) Initialize git:
   - `cd "$WORKSPACE_ROOT" && git init && git add -A && git commit -m "chore: initial extract"`
   - If any git command fails, print `SMOKE_TEST_FAIL setup: git failed` and stop.
5) Set `TARGET_ROOT` = resolved `WORKSPACE_ROOT` (absolute path).
6) Print `SMOKE_SETUP_OK TARGET_ROOT=` followed by the resolved path.

## Phase Execution

Execute these phase specs in order:
1) `"$PROMPT_ROOT/smoke/phases/phase-01-new-project.md"`
2) `"$PROMPT_ROOT/smoke/phases/phase-02-plan.md"`
3) `"$PROMPT_ROOT/smoke/phases/phase-03-run.md"`
4) `"$PROMPT_ROOT/smoke/phases/phase-04-review.md"`
5) `"$PROMPT_ROOT/smoke/phases/phase-05-feature.md"`
6) `"$PROMPT_ROOT/smoke/phases/phase-06-plan-2.md"`
7) `"$PROMPT_ROOT/smoke/phases/phase-07-run-2.md"`
8) `"$PROMPT_ROOT/smoke/phases/phase-08-review-2.md"`

## Final Report

Print git log summary: `cd "$TARGET_ROOT" && git log --oneline`
Print: `TARGET_ROOT="$TARGET_ROOT"`
Print: `✅ RW smoke test completed successfully. All phases passed.`

Final line (must be the very last line of output):
`SMOKE_TEST_PASS total_phases=8 dispatches=<total-subagent-dispatches>`
