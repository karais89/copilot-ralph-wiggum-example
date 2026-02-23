# Ralph Wiggum Orchestration Template

Minimal orchestration framework for a Plan -> Run -> Review workflow.

## What Changed

This repo now keeps only the core contracts needed for day-to-day execution:

- 7 core prompts
- 1 orchestrator agent entrypoint
- 2 orchestrator phase subagent prompts
- slim helper scripts (`status`, `next`)
- shell-based smoke test as the primary end-to-end verifier

Removed as redundant:

- `rw-init`
- `rw-doctor`
- prompt-driven smoke module (`rw-smoke-test.prompt.md`, `prompts/smoke/*`)
- separate target registry script (merged into resolver)
- plan approval gate flow

## Core Prompts

- `.github/prompts/rw-new-project.prompt.md`
- `.github/prompts/rw-onboard-project.prompt.md`
- `.github/prompts/rw-feature.prompt.md`
- `.github/prompts/rw-plan.prompt.md`
- `.github/prompts/rw-run.prompt.md`
- `.github/prompts/rw-review.prompt.md`
- `.github/prompts/rw-archive.prompt.md`

Agent entrypoint:

- `.github/agents/rw-orchestrator.agent.md`

Subagent prompt contracts:

- `.github/prompts/orchestrator/rw-orchestrator-feature-phase.subagent.md`
- `.github/prompts/orchestrator/rw-orchestrator-plan-phase.subagent.md`

## Scripts

Core:

- `scripts/orchestration/rw-bootstrap-scaffold.sh`
- `scripts/orchestration/rw-resolve-target-root.sh`
- `scripts/rw-smoke-test.sh`
- `scripts/validation/check-prompts.mjs`

Support:

- `scripts/rw` (`status`, `next`)
- `scripts/validation/validate-smoke-result.sh`
- `scripts/template/extract-template.sh`

## Quick Start

1. Extract template into a target repository:

```bash
./scripts/template/extract-template.sh /path/to/target
cd /path/to/target
```

2. Use either:
   - `rw-orchestrator` (single-entry autonomous flow), or
   - manual flow: `rw-new-project` -> `rw-plan` -> `rw-run` -> `rw-review`

3. For existing repositories, start with:
   - `rw-onboard-project` -> `rw-feature` -> `rw-plan` -> `rw-run` -> `rw-review`

## Target Root Resolution

All runtime prompts resolve target root through:

- `.github/prompts/shared/RW-TARGET-ROOT-RESOLUTION.md`
- `scripts/orchestration/rw-resolve-target-root.sh`

Default resolution:

```bash
./scripts/orchestration/rw-resolve-target-root.sh resolve-active "$(pwd)"
```

Set active target explicitly:

```bash
./scripts/orchestration/rw-resolve-target-root.sh set-active "$(pwd)" my-project "/absolute/path/to/project"
```

## Helper Script

`scripts/rw` is intentionally minimal:

```bash
./scripts/rw status
./scripts/rw next
```

It reads active workspace state and prints `NEXT_COMMAND` recommendations.

## Validation

Prompt contract validation:

```bash
node scripts/validation/check-prompts.mjs
```

End-to-end smoke validation:

```bash
./scripts/rw-smoke-test.sh
```

Result schema check (used by smoke script):

```bash
./scripts/validation/validate-smoke-result.sh <last-result.json> .ai/templates/SMOKE-RESULT-SCHEMA.json
```

## Notes

- Machine tokens in `.ai/CONTEXT.md` are part of contract and must remain unchanged.
- `rw-run` keeps one-dispatch/one-completion and verification-evidence invariants.
- `rw-review` remains the single place for batch review state transitions.
