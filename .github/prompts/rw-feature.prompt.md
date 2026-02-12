---
name: rw-feature
description: "Create one READY_FOR_PLAN feature file under .ai/features before rw-plan."
agent: agent
argument-hint: "One-line feature summary (recommended). Example: add export command with date filter."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Prepare one feature input file for planning.
- Write exactly one new `.ai/features/YYYYMMDD-HHMM-<slug>.md` file.
- Set `Status: READY_FOR_PLAN` so `rw-plan` can consume it.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

Feature summary: ${input:featureSummary:One-line feature summary. Example: add export command with date filter.}
Non-interactive marker (optional): include literal token `[NON_INTERACTIVE]` in `featureSummary` to force non-interactive flow.

You are preparing feature input for Ralph orchestration.

Target files:
- `.ai/features/YYYYMMDD-HHMM-<slug>.md` (required, create exactly one)
- `.ai/features/FEATURE-TEMPLATE.md` (create only if missing)
- `.ai/features/README.md` (create only if missing)

Rules:
- Do not edit `.ai/PLAN.md`, `.ai/PROGRESS.md`, or `.ai/tasks/*`.
- Do not create any `TASK-XX` files or PROGRESS log/status entries in rw-feature.
- Prefer ASCII slug/file names.
- Keep machine tokens unchanged: `Status`, `READY_FOR_PLAN`.
- Do not overuse multiple-choice questions; use them only when they reduce ambiguity quickly.
- Clarification-first: if any high-impact ambiguity remains, ask follow-up questions persistently before using defaults, except in non-interactive mode.
- Interactive fallback must follow `.github/prompts/RW-INTERACTIVE-POLICY.md`.
- Non-interactive mode:
  - Enable when either:
    - `featureSummary` contains literal token `[NON_INTERACTIVE]`, or
    - `.ai/runtime/rw-noninteractive.flag` exists.
  - In this mode, never call `#tool:vscode/askQuestions` and never ask interactive follow-up questions.
  - Resolve missing values with safe defaults (`AI_DECIDE` equivalent) and continue.
- Write `.ai/features/*.md` content in the user-document language resolved from `.ai/CONTEXT.md`.
- If language policy is ambiguous for user-facing prose, default to Korean.
- Keep only parser/machine tokens in English (`Status`, `READY_FOR_PLAN`, `PLANNED`, file/status tokens in notes if any).

Workflow:
1) Ensure `.ai/features/` exists; create it if missing.
2) If `.ai/features/FEATURE-TEMPLATE.md` is missing, create a template with sections:
   - `Summary`, `User Value`, `Goal`, `In Scope`, `Out of Scope`, `Functional Requirements`, `Constraints`, `Acceptance`, `Edge Cases and Error Handling`, `Verification Baseline`, `Risks and Open Questions`, `Notes`
3) If `.ai/features/README.md` is missing, create a minimal usage note with status flow (`DRAFT` -> `READY_FOR_PLAN` -> `PLANNED`).
4) Resolve output language for user-facing prose from `.ai/CONTEXT.md` (user document language policy).
5) Resolve `NON_INTERACTIVE_MODE` first:
   - true if `featureSummary` contains `[NON_INTERACTIVE]` OR `.ai/runtime/rw-noninteractive.flag` exists.
   - if marker token is present in `featureSummary`, remove only that marker token and keep remaining text.
6) Resolve initial summary:
   - Use `featureSummary` if provided.
   - If missing and `NON_INTERACTIVE_MODE=true`, use default summary:
     - `Add a command to export action-item lists as a markdown report.`
   - If missing and `NON_INTERACTIVE_MODE=false`, use `#tool:vscode/askQuestions` with one open-ended question written in the resolved user-document language from Step 4.
   - Question intent (do not hardcode this English string in output): "What feature should be added? (Example: add export command with date filter)"
   - If `NON_INTERACTIVE_MODE=false` and `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
   - If `NON_INTERACTIVE_MODE=false` and still missing after that single interaction, stop immediately and output exactly: `FEATURE_SUMMARY_MISSING`.
7) If high-impact ambiguity remains after reading summary + repository context, run clarification rounds:
   - If `NON_INTERACTIVE_MODE=true`, skip interactive rounds and apply defaults (`AI_DECIDE` equivalent).
   - If `NON_INTERACTIVE_MODE=false`, run 2~5 rounds while ambiguity remains.
   - Each round asks 1~3 focused questions.
   - Prefer single-choice options (2-4 choices + optional `AI_DECIDE`) when practical.
   - Use short open-ended questions only when options are not practical.
   - Clarify at least:
     - primary user flow
     - exact behavior/output expectations
     - in-scope vs out-of-scope boundaries
     - key edge cases and failure behavior
     - verification baseline command/evidence
   - Clarification questions/options must be written in the resolved user-document language from Step 4.
   - If `NON_INTERACTIVE_MODE=false` and `#tool:vscode/askQuestions` is unavailable, apply one-time chat fallback exactly per `.github/prompts/RW-INTERACTIVE-POLICY.md`.
8) If details are still insufficient after clarification rounds, apply safe defaults and explicitly record assumptions:
   - Constraints: backward compatible, minimal scope, project-defined canonical validation commands must pass.
   - Acceptance: user-visible behavior works, clear error messages, and at least one canonical verification command succeeds with exit code 0.
9) Build slug from summary and generate filename `YYYYMMDD-HHMM-<slug>.md` using local time.
   - If same filename already exists, append `-v2`, `-v3`, ...
10) Create exactly one feature file with this structure:
   - `# FEATURE: <slug>`
   - `Status: READY_FOR_PLAN`
   - `## Summary`
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
   Populate sections in detail using the summary and defaults. Include concrete, testable bullet points written in the resolved user-document language.
11) In `Notes`, include:
   - source (`rw-feature`)
   - created timestamp
   - recommended next step (`rw-plan`)

Output format at end:
- Created feature file path
- Final status value
- One-line summary used
- Clarification questions asked count
- Recommended next command (`rw-plan`)
