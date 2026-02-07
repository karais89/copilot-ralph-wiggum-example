Title: Add unit and integration tests for JSON output

Dependencies: TASK-14, TASK-15

Description:
- Implement tests that verify valid JSON output, correct schema keys/types, and error-case JSON formatting. Ensure tests run in CI/local `npm test`.

Acceptance Criteria:
- Tests cover: normal case (non-empty todos), empty todos, partial data case (simulate data unavailable), and error case (force internal error).
- `npm test` passes locally.

Files to Create/Modify:
- `test/stats-json.test.ts` (new)
- `package.json` test script if needed (verify existing script)

Verification:
- Run `npm test` and confirm the new tests pass.
