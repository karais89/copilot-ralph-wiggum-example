---
name: rw-new-project
description: "Integrated new-project bootstrap: rw-init scaffolding + interactive discovery in one prompt."
agent: agent
argument-hint: "Optional one-line project idea. Example: shared travel itinerary planner."
---

Language policy reference: `.ai/CONTEXT.md`

Quick summary:
- Use this prompt when the repository is new/empty and project intent is not yet defined.
- Perform minimal workspace scaffolding (`CONTEXT`, `PLAN`, `PROGRESS`, optional `TASK-01`) and project discovery in one run.
- Update `PLAN.md` overview and create one discovery note under `.ai/notes/`.

Step 0 (Mandatory):
1) Read `.ai/CONTEXT.md` first.
2) If `.ai/CONTEXT.md` is missing, create it first with a minimal bootstrap language-policy template, then read it.
3) If `.ai/CONTEXT.md` exists but is unreadable, stop immediately and output exactly: `LANG_POLICY_MISSING`
4) Validate language policy internally and proceed silently (no confirmation line).
5) Do not modify any file before Step 0 completes, except creating `.ai/CONTEXT.md` when missing.

Bootstrap template for `.ai/CONTEXT.md` (when missing):
- `# 워크스페이스 컨텍스트`
- `## 언어 정책`
  - Prompt body language (`.github/prompts/*.prompt.md`): English (required)
  - User document language (`.ai/*` docs): Korean by default
  - Commit message language: English (Conventional Commits)
- `## 기계 파싱 토큰 (번역 금지)`
  - `Task Status`, `Log`
  - `pending`, `in-progress`, `completed`
  - `LANG_POLICY_MISSING`
- `## 프롬프트 작성 규칙`
  - Every prompt reads `.ai/CONTEXT.md` first via Step 0

Project idea input (optional): ${input:projectIdea:Optional one-line project idea. Example: shared travel itinerary planner.}

You are initializing a new Ralph orchestration workspace and defining initial project direction.

Target files:
- `.ai/CONTEXT.md` (create only if missing)
- `.ai/PLAN.md` (required)
- `.ai/PROGRESS.md` (required)
- `.ai/tasks/TASK-01-bootstrap-workspace.md` (optional, create only when no task files exist)
- `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` (required, create exactly one)

Rules:
- Do not edit product code.
- Do not create or edit `.ai/features/*.md` in this prompt.
- Do not create any `TASK-02` or higher.
- Create at most one task file during this prompt (`TASK-01-bootstrap-workspace.md`).
- Keep existing `PROGRESS` task rows/log entries unchanged on rerun; add only missing task rows.
- Keep `.ai/PLAN.md` concise; do not add full PRD/spec decomposition.
- Keep machine tokens untouched where present (`Task Status`, `Log`, status enums).
- Write user-facing content in language resolved from `.ai/CONTEXT.md` (default Korean if ambiguous).
- Keep task section headers unchanged (`Title`, `Dependencies`, `Description`, `Acceptance Criteria`, `Files to Create/Modify`, `Verification`) and write section values/prose in the resolved user-document language.
- Clarification-first: for ambiguous requirements, ask follow-up questions persistently before applying defaults.

Workflow:
1) Ensure scaffolding directories exist:
   - `.ai/`, `.ai/tasks/`, `.ai/notes/`, `.ai/progress-archive/`
2) Bootstrap minimal workspace files:
   - `PLAN.md`:
     - If missing, create:
       - `# <repository-name>`
       - `## 개요`
       - `- 프로젝트 목적 미정 (사용자 입력 필요).`
       - `- 기술 스택 미정.`
       - `- 다음 단계: 이 프롬프트에서 방향을 확정하고 rw-feature를 실행하세요.`
       - `## Feature Notes (append-only)`
     - If exists, keep content and ensure `## Feature Notes (append-only)` section exists.
   - `TASK-01`:
     - If no `TASK-XX-*.md` exists, create `TASK-01-bootstrap-workspace.md` with:
       - Title
       - Dependencies
       - Description
       - Acceptance Criteria
       - Files to Create/Modify
       - Verification
       - Keep the section headers above exactly as written, but write all values/prose in the resolved user-document language.
   - `PROGRESS.md`:
     - If missing, create:
       - `# 진행 현황`
       - `## Task Status`
       - `| Task | Title | Status | Commit |`
       - `|------|-------|--------|--------|`
       - one row per existing task file as `pending` with commit `-`
       - `## Log`
       - `- **YYYY-MM-DD** — Initial workspace scaffolded by rw-new-project.`
     - If exists, keep existing rows/logs and add only missing task rows as `pending`.
     - For newly added rows, write the `Title` value in the same resolved user-document language.
3) Resolve initial direction input:
   - If `projectIdea` is present, use it as seed.
   - If missing, ask one open-ended question using `#tool:vscode/askQuestions`:
     - intent: "What product/project do you want to build first?"
   - If `#tool:vscode/askQuestions` is unavailable, ask once in chat.
   - If still missing after one interaction, stop immediately and output exactly: `PROJECT_IDEA_MISSING`.
4) Clarification rounds (interactive, persistent):
   - Run 3~6 short clarification rounds when ambiguity exists.
   - In each round, ask 1~3 focused questions (single-choice preferred when practical).
   - Resolve all of the following before finalizing (unless user explicitly chooses `AI_DECIDE`):
     - target users
     - core user value/problem
     - MVP in-scope vs out-of-scope
     - constraints/preferences (stack/time/risk)
     - one verification baseline command (if known)
   - Prefer single-choice options where practical; use short open-ended questions only when options are not practical.
   - Do not settle early if ambiguity remains and question budget is still available.
   - Apply defaults only when:
     - user explicitly selects `AI_DECIDE`, or
     - round budget is exhausted.
   - Record every unresolved ambiguity in `## Open Questions` and `## Assumptions and Defaults Used`.
5) Update `.ai/PLAN.md` overview:
   - Keep title line (`# ...`) unchanged unless missing.
   - Replace placeholder-style overview lines when present.
   - If overview already has meaningful content, append a dated direction update block instead of full rewrite.
   - Ensure `## Feature Notes (append-only)` exists and remains unchanged.
   - Keep overview to 5-10 concise lines:
     - project purpose
     - target users
     - MVP scope
     - key constraints
     - verification baseline
6) Create exactly one discovery note file:
   - Path: `.ai/notes/PROJECT-CHARTER-YYYYMMDD.md` (local date)
   - If same-day file exists, append `-v2`, `-v3`, ...
   - Required sections:
     - `# Project Charter`
     - `## Summary`
     - `## Target Users`
     - `## Problem and Value`
     - `## MVP In Scope`
     - `## Out of Scope`
     - `## Constraints and Preferences`
     - `## Verification Baseline`
     - `## Open Questions`
     - `## Assumptions and Defaults Used`
     - `## Recommended Next Step`
   - In `Recommended Next Step`, recommend `rw-feature`.
7) Idempotency:
   - Rerunning this prompt must not erase existing history (`PLAN Feature Notes`, `PROGRESS` logs/rows).
   - Apply additive/minimal updates only when files already exist.

Output format at end:
- Scaffolding result (`PLAN`/`PROGRESS`/`TASK-01`)
- PLAN overview update result (updated/appended)
- Charter note file path
- Clarification rounds used count
- Unresolved open questions count
- Recommended next command (`rw-feature`)
