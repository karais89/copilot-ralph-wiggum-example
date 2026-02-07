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
- Set `Status: READY_FOR_PLAN` so `rw-plan-lite`/`rw-plan-strict` can consume it.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If the file is missing or unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
3) Validate language policy internally and proceed silently (no confirmation line).
4) Do not modify any file before Step 0 completes.

Feature summary: ${input:featureSummary:One-line feature summary. Example: add export command with date filter.}

You are preparing feature input for Ralph orchestration.

Target files:
- `.ai/features/YYYYMMDD-HHMM-<slug>.md` (required, create exactly one)
- `.ai/features/FEATURE-TEMPLATE.md` (create only if missing)
- `.ai/features/README.md` (create only if missing)

Rules:
- Do not edit `.ai/PLAN.md`, `.ai/PROGRESS.md`, or `.ai/tasks/*`.
- Prefer ASCII slug/file names.
- Keep machine tokens unchanged: `Status`, `READY_FOR_PLAN`.
- Do not use multiple-choice questions.
- Keep interaction minimal: ask clarification questions only if high-impact ambiguity remains after reading `featureSummary`.
- Write `.ai/features/*.md` content in Korean by default.
- Keep only parser/machine tokens in English (`Status`, `READY_FOR_PLAN`, `PLANNED`, file/status tokens in notes if any).

Workflow:
1) Ensure `.ai/features/` exists; create it if missing.
2) If `.ai/features/FEATURE-TEMPLATE.md` is missing, create a template with sections:
   - `Goal`, `Constraints`, `Acceptance`, `In Scope`, `Out of Scope`, `Functional Requirements`, `Edge Cases and Error Handling`, `Verification Baseline`, `Notes`
3) If `.ai/features/README.md` is missing, create a minimal usage note with status flow (`DRAFT` -> `READY_FOR_PLAN` -> `PLANNED`).
4) Resolve initial summary:
   - Use `featureSummary` if provided.
   - If missing, ask one short direct question: "What feature should be added?"
   - If still missing after that question, stop immediately and output exactly: `FEATURE_SUMMARY_MISSING`.
5) Ask up to 2 short open clarifying questions only when necessary for high-impact ambiguity.
6) If user does not provide enough detail after questions, apply safe defaults:
   - Constraints: backward compatible, minimal scope, `npm run build` must pass.
   - Acceptance: user-visible behavior works, clear error messages, `npm run build` passes.
7) Build slug from summary and generate filename `YYYYMMDD-HHMM-<slug>.md` using local time.
   - If same filename already exists, append `-v2`, `-v3`, ...
8) Create exactly one feature file with this structure:
   - `# FEATURE: <slug>`
   - `Status: READY_FOR_PLAN`
   - `## Summary` (한국어)
   - `## User Value` (한국어)
   - `## Goal`
   - `## In Scope` (한국어)
   - `## Out of Scope` (한국어)
   - `## Functional Requirements` (한국어)
   - `## Constraints`
   - `## Acceptance`
   - `## Edge Cases and Error Handling` (한국어)
   - `## Verification Baseline` (한국어)
   - `## Risks and Open Questions` (한국어)
   - `## Notes`
   Populate sections in detail using the summary and defaults. Include concrete, testable bullet points written in Korean.
9) In `Notes`, include:
   - source (`rw-feature`)
   - created timestamp
   - recommended next step (`rw-plan-lite` or `rw-plan-strict`)

Output format at end:
- Created feature file path
- Final status value
- One-line summary used
- Clarification questions asked count
- Recommended next command (`rw-plan-lite` or `rw-plan-strict`)
