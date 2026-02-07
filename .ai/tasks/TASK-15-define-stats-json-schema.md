Title: Define minimal JSON schema for `stats --json`

Dependencies: TASK-14

Description:
- Specify and document the minimal JSON schema that `stats --json` will emit. Focus on required fields only for initial implementation.

Acceptance Criteria:
- JSON schema includes required numeric fields: `total`, `completed`, `pending`, `overdue` and a string field `generated_at` (ISO-8601).
- Error output schema: object with `error` and `message` fields.

Files to Create/Modify:
- `.ai/features/20260207-1906-add-stats-command-json-output-mode.md` (reference)
- `docs/` or README examples (small snippet)

Verification:
- Schema documented in the feature file and README; unit tests validate emitted JSON keys and types.
