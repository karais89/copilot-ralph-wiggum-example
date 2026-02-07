# Workspace Context

## Language Policy

- Prompt instruction language (`.github/prompts/*.prompt.md`): English (required)
- Prompt preflight: each prompt must include `Step 0 (Mandatory)` to load this file before any modification
- User-facing docs language (`.ai/GUIDE.md`, `.ai/PLAN.md`, `.ai/PROGRESS.md`, `.ai/tasks/*.md`, `.ai/notes/*.md`): Korean by default
- Commit message language: English (Conventional Commits)
- Conflict rule: If language is mixed or ambiguous, this file takes precedence.

## Machine-Parsed Tokens (DO NOT TRANSLATE)

These tokens are contract values used by orchestration prompts/parsers and must stay exactly as written.

- In `.ai/PROGRESS.md` section headers:
  - `## Task Status`
  - `## Log`
- In `.ai/PROGRESS.md` table header:
  - `| Task | Title | Status | Commit |`
- In `.ai/PROGRESS.md` status values:
  - `pending`
  - `in-progress`
  - `completed`
- Task ID format:
  - `TASK-XX` (zero-padded numeric IDs)
- Review markers in logs:
  - `REVIEW_FAIL`
  - `REVIEW-ESCALATE`
- Prompt preflight output tokens:
  - `LANG_POLICY_MISSING`
  - `LANGUAGE_POLICY_LOADED: <single-line summary>`
- File/path contracts:
  - `.ai/PAUSE.md`
  - `.ai/progress-archive/STATUS-*.md`
  - `.ai/progress-archive/LOG-*.md`
  - `## Feature Notes (append-only)` in `.ai/PLAN.md`

## Prompt Authoring Rules

1. Keep one dominant language per prompt body (avoid line-level mixing).
2. Add `Step 0 (Mandatory)` to read `.ai/CONTEXT.md` before any file edit.
3. If `.ai/CONTEXT.md` is missing or unreadable, stop with `LANG_POLICY_MISSING`.
4. Keep output/report formats in one language per section (do not mix in one bullet/table row).

## Additional Guardrails

1. Korean prose is allowed around machine tokens, but machine tokens themselves must remain unchanged.
2. Never rename `Task Status`, `Log`, or status enum values even when translating docs.
3. Keep append-only intent:
   - `.ai/PLAN.md`: append in `Feature Notes` only
   - `.ai/PROGRESS.md` Log: append new entries, avoid destructive rewrites unless archiving
4. Run/archive safety:
   - Do not run concurrent orchestrators in the same workspace.
   - Run `rw-archive` only while `.ai/PAUSE.md` exists.
