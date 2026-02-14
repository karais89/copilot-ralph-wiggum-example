# AGENTS.md

Repository-specific instructions for Codex agents working in this project.

## Scope

- Applies to the entire repository at this root.
- Use these rules together with system/developer instructions.

## Source of Truth

- Product/workflow behavior: `.ai/GUIDE.md`
- Language/token policy: `.ai/CONTEXT.md`
- Public project usage docs: `README.md`
- Orchestration prompts: `.github/prompts/rw-*.prompt.md`

## Branch Strategy (Required)

- Use github-flow.
- Do not work directly on `main`.
- Create a short-lived branch first: `codex/<short-topic>`.
- Commit on the working branch, open PR, squash merge, then delete branch.
- If the current branch is `main`, create/switch to a `codex/*` branch before editing.

## Change Rules

- Keep parser-safe tokens in English exactly as defined (`Task Status`, `Log`, `pending`, `in-progress`, `completed`, error tokens).
- Prompt body language stays English; `.ai/*` user-facing docs default to Korean unless policy says otherwise.
- For orchestration changes, prefer minimal diffs and preserve existing machine-readable tokens/contracts.
- If you add or move template assets/prompts/scripts used by extraction, update `scripts/extract-template.sh` accordingly.

## Validation Rules

- When changing prompts/scripts/templates related to RW orchestration, run:
  - `./scripts/rw-smoke-test.sh`
- When changing smoke result contract/schema/validation, ensure:
  - `scripts/validate-smoke-result.sh` still validates generated `last-result.json`.
- For app/runtime code changes, run relevant project checks (`npm run build`, `npm test`) as applicable.

## Commit Rules

- Use Conventional Commit style.
- Keep commits focused by concern (prompt rules vs script logic vs docs).
- In commit/PR summary, include what was validated.

## Safety Notes

- Do not remove mandatory `Step 0` guards or required stop tokens without explicit request.
- Do not weaken `rw-run` task-lock/completion-delta invariants unless explicitly requested.
