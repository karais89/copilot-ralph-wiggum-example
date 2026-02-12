---
name: rw-feature
description: "Create one READY_FOR_PLAN feature file with a mandatory user-need gate before rw-plan."
agent: agent
argument-hint: "One-line feature summary (recommended). Example: add export command with date filter."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Prepare one feature input file for planning.
- Write exactly one new `.ai/features/YYYYMMDD-HHMM-<slug>.md` file.
- Set `Status: READY_FOR_PLAN` so `rw-plan` can consume it.
- Set `Planning Profile: STANDARD` by default (optional override to `FAST_TEST` for quick test planning).
- Validate the feature need explicitly (`User`, `Problem`, `Desired Outcome`, `Acceptance Signal`).

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

Feature summary: ${input:featureSummary:One-line feature summary. Example: add export command with date filter.}

You are preparing feature input for Ralph orchestration.

Target files:
- `.ai/features/YYYYMMDD-HHMM-<slug>.md` (required, create exactly one)

Rules:
- Do not edit `.ai/PLAN.md`, `.ai/PROGRESS.md`, or `.ai/tasks/*`.
- Do not create any `TASK-XX` files or PROGRESS log/status entries in rw-feature.
- Prefer ASCII slug/file names.
- Keep machine tokens unchanged: `Status`, `READY_FOR_PLAN`, `Planning Profile`, `STANDARD`, `FAST_TEST`.
- Must resolve the feature need with four fields:
  - `User`
  - `Problem`
  - `Desired Outcome`
  - `Acceptance Signal`
- Interactive clarification limit:
  - at most one clarification round
  - at most two focused questions total
- Interactive fallback must follow `.github/prompts/RW-INTERACTIVE-POLICY.md`.
- Non-interactive mode is enabled only when `.ai/runtime/rw-noninteractive.flag` exists.
- In non-interactive mode, never call `#tool:vscode/askQuestions`; fill missing fields with explicit assumptions.
- Write `.ai/features/*.md` content in the user-document language resolved from `.ai/CONTEXT.md`.
- If language policy is ambiguous for user-facing prose, default to Korean.
- Keep only parser/machine tokens in English (`Status`, `READY_FOR_PLAN`, `PLANNED`, file/status tokens in notes if any).

Workflow:
1) Ensure `.ai/features/` exists; create it if missing.
2) Resolve output language for user-facing prose from `.ai/CONTEXT.md` (user document language policy).
3) Resolve `NON_INTERACTIVE_MODE`:
   - true only if `.ai/runtime/rw-noninteractive.flag` exists.
4) Resolve initial summary:
   - Use `featureSummary` if provided.
   - If missing and `NON_INTERACTIVE_MODE=true`, use default summary:
     - `Add a command to export action-item lists as a markdown report.`
   - If missing and `NON_INTERACTIVE_MODE=false`, use `#tool:vscode/askQuestions` with one open-ended question written in the resolved user-document language from Step 2.
   - Question intent (do not hardcode this English string in output): "What feature should be added? (Example: add export command with date filter)"
   - If `NON_INTERACTIVE_MODE=false` and `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
   - If `NON_INTERACTIVE_MODE=false` and still missing after that single interaction, stop immediately and output exactly: `FEATURE_SUMMARY_MISSING`.
5) Build an initial need snapshot from summary + repository context:
   - `User`
   - `Problem`
   - `Desired Outcome`
   - `Acceptance Signal`
6) Need-gate handling:
   - Missing critical fields are: `User`, `Problem`, `Desired Outcome`.
   - If `NON_INTERACTIVE_MODE=false` and any critical field is missing, run exactly one clarification round with at most two focused questions.
   - If `NON_INTERACTIVE_MODE=false` and `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
   - If `NON_INTERACTIVE_MODE=true`, do not ask; fill missing fields with conservative defaults and mark them as assumptions.
7) Re-evaluate need-gate:
   - If any critical field remains missing, stop immediately and output:
     - first line exactly: `FEATURE_NEED_INSUFFICIENT`
     - second line: `MISSING_FIELDS=<comma-separated-field-names>`
8) If `Acceptance Signal` is still missing, set a safe default:
   - At least one project-defined canonical verification command succeeds with exit code 0.
9) Build slug from summary and generate filename `YYYYMMDD-HHMM-<slug>.md` using local time.
   - If same filename already exists, append `-v2`, `-v3`, ...
10) Create exactly one feature file with this structure:
   - `# FEATURE: <slug>`
   - `Status: READY_FOR_PLAN`
   - `Planning Profile: STANDARD`
   - `## Summary`
   - `## Need Statement`
     - `- User: ...`
     - `- Problem: ...`
     - `- Desired Outcome: ...`
     - `- Acceptance Signal: ...`
   - `## User Value`
   - `## Goal`
   - `## In Scope`
   - `## Out of Scope`
   - `## Functional Requirements`
   - `## Constraints`
   - `## Acceptance`
   - `## Edge Cases and Error Handling`
   - `## Verification Baseline`
   - `## Risks and Open Questions`
   - `## Notes`
   Populate sections in detail using the resolved need fields and defaults. Include concrete, testable bullet points written in the resolved user-document language.
11) In `Notes`, include:
   - source (`rw-feature`)
   - created timestamp
   - recommended next step (`rw-plan`)
   - explicit assumptions list (if any defaults were used for missing need fields)

Output format at end:
- `FEATURE_FILE=<created-feature-file-path>`
- `FEATURE_STATUS=<READY_FOR_PLAN>`
- `SUMMARY_USED=<one-line-summary>`
- `NEED_GATE_STATUS=<PASS>`
- `CLARIFICATION_QUESTION_COUNT=<n>`
- `NEXT_COMMAND=rw-plan`
