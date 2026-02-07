---
name: rw-feature
description: "Create one READY_FOR_PLAN feature file under .ai/features before rw-plan."
agent: agent
argument-hint: "Optional one-line feature summary. Ask exactly 2 multiple-choice questions (A/B/C) and wait for answers before writing files."
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

Feature summary: ${input:featureSummary:Optional one-line feature summary. If empty or ambiguous, ask short clarification questions before writing files.}

You are preparing feature input for Ralph orchestration.

Target files:
- `.ai/features/YYYYMMDD-HHMM-<slug>.md` (required, create exactly one)
- `.ai/features/FEATURE-TEMPLATE.md` (create only if missing)
- `.ai/features/README.md` (create only if missing)

Rules:
- Do not edit `.ai/PLAN.md`, `.ai/PROGRESS.md`, or `.ai/tasks/*`.
- Prefer ASCII slug/file names.
- Keep machine tokens unchanged: `Status`, `READY_FOR_PLAN`.
- Before writing any feature file, ask exactly 2 clarification questions.
- Each clarification question must be multiple-choice with exactly 3 options: `A`, `B`, `C`.
- Ask both questions in one message and wait for user answers.
- Accept these answer formats case-insensitively:
  - `Q1:A, Q2:B`
  - `A,B`
  - `A B`
- Normalize lowercase answers (for example `a, a`) to uppercase before validation.
- If answers are missing or invalid on first attempt, print `FEATURE_CHOICE_REQUIRED`, reprint the 2 questions, and wait once.
- If still invalid after one retry, apply defaults `Q1:B, Q2:B` and continue (do not loop).

Workflow:
1) Ensure `.ai/features/` exists; create it if missing.
2) If `.ai/features/FEATURE-TEMPLATE.md` is missing, create a minimal template with sections: `Goal`, `Constraints`, `Acceptance`, `Notes`.
3) Resolve initial summary:
   - Use `featureSummary` if provided.
   - If missing, ask one direct question: "What feature should be added?"
4) Ask exactly 2 multiple-choice clarification questions and wait for the user's choice string:
   - Q1 should decide scope level (minimal / balanced / extended).
   - Q2 should decide compatibility/quality bar (fast / standard / strict).
   - Each question must have options A/B/C and one recommended option.
   - Parse answers using the accepted formats above.
   - Do not write files before choices are resolved (user choices or default fallback `B,B`).
5) If user does not provide enough detail after questions, apply safe defaults:
   - Constraints: backward compatible, minimal scope, `npm run build` must pass.
   - Acceptance: user-visible behavior works, clear error messages, `npm run build` passes.
6) Build slug from summary and generate filename `YYYYMMDD-HHMM-<slug>.md` using local time.
   - If same filename already exists, append `-v2`, `-v3`, ...
7) Create exactly one feature file with this structure:
   - `# FEATURE: <slug>`
   - `Status: READY_FOR_PLAN`
   - `## Goal`
   - `## Constraints`
   - `## Acceptance`
   - `## Notes`
8) In `Notes`, include:
   - source (`rw-feature`)
   - created timestamp
   - recommended next step (`rw-plan-lite` or `rw-plan-strict`)

Output format at end:
- Created feature file path
- Final status value
- One-line summary used
- Choice answers used (`Q1`, `Q2`)
- Choice source (`user` or `default-after-invalid`)
- Recommended next command (`rw-plan-lite` or `rw-plan-strict`)
