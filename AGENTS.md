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
- Smoke orchestration entry prompt: `.github/prompts/rw-smoke-test.prompt.md`
- Historical verification reference (non-authoritative): `.ai/RW-VERIFICATION-REPORT.md`

## Branch Strategy (Required)

- Use github-flow.
- Do not work directly on `main`.
- Create a short-lived branch first: `codex/<short-topic>`.
- Commit on the working branch, open PR, squash merge, then delete branch.
- If the current branch is `main`, create/switch to a `codex/*` branch before editing.

## Branch Lifecycle Policy (Required)

- Keep active working branches limited: default max 1 local `codex/*` branch (temporary max 2 only for urgent parallel fixes).
- Before starting a new branch, inspect existing `codex/*` branches and clean already-merged ones first.
- After first push, open a Draft PR immediately so branch ownership/state is explicit.
- After validation passes and push is done, explicitly ask whether to:
  - merge now,
  - keep Draft PR open, or
  - close and delete the branch.
- If merge is completed (by agent action or user confirmation), finish with:
  - `git switch main`
  - `git pull --ff-only origin main`
  - `scripts/cleanup-branches.sh --apply` (and `--delete-remote` when requested)
- For stale branches (no updates for 3+ days), ask to close/rebase before starting new work.
- Use `scripts/cleanup-branches.sh` for deterministic branch cleanup.

## Change Rules

- Keep parser-safe tokens in English exactly as defined (`Task Status`, `Log`, `pending`, `in-progress`, `completed`, error tokens).
- Prompt body language stays English; `.ai/*` user-facing docs default to Korean unless policy says otherwise.
- Entry prompt selection:
  - Use `rw-new-project` for new/empty repositories.
  - Use `rw-onboard-project` for existing codebases, then follow `NEXT_COMMAND=rw-feature`.
- For orchestration changes, prefer minimal diffs and preserve existing machine-readable tokens/contracts.
- If you add or move template assets/prompts/scripts used by extraction, update `scripts/extract-template.sh` accordingly.

## Validation Rules

- When changing prompts/scripts/templates related to RW orchestration, run:
  - `node scripts/check-prompts.mjs`
  - `./scripts/rw-smoke-test.sh`
- When changing smoke result contract/schema/validation, ensure:
  - `scripts/validate-smoke-result.sh` still validates generated `last-result.json`.
- For app/runtime code changes, run relevant project checks (`npm run build`, `npm test`) as applicable.

## Commit Rules

- Use Conventional Commit style.
- Keep commits focused by concern (prompt rules vs script logic vs docs).
- In commit/PR summary, include what was validated.

## Completion Handshake (Required)

- For any non-readonly task that changed files, after commit you must explicitly ask merge intent before ending.
- This is required for both `commit only` and `commit + push` flows.
- Default closing question:
  - `작업 완료했습니다. main으로 머지(또는 PR 생성)할까요?`
- Even if user explicitly requested push, do not treat push as final closure; ask merge/PR intent after reporting push result.
- Do not assume merge automatically unless user explicitly requested merge.
- You may skip the merge/PR question only when user explicitly says to end without further actions.

## Safety Notes

- Do not remove mandatory `Step 0` guards or required stop tokens without explicit request.
- Do not weaken `rw-run` task-lock/completion-delta invariants unless explicitly requested.
