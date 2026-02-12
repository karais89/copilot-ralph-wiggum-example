# Workspace Context

## Language Policy
- Prompt body language (`.github/prompts/rw-*.prompt.md`): English (required)
- User document language (`.ai/*` docs): Korean by default
- Commit message language: English (Conventional Commits)

## Machine-Parsed Tokens (Do Not Translate)
- `Task Status`, `Log`
- `pending`, `in-progress`, `completed`
- `LANG_POLICY_MISSING`

## Prompt Authoring Rules
- Every orchestration prompt (`rw-*`) reads `.ai/CONTEXT.md` first via Step 0
