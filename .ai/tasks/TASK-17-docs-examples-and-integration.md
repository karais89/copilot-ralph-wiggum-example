Title: Documentation examples and small integration test

Dependencies: TASK-14, TASK-15, TASK-16

Description:
- Add example usage to README and feature docs demonstrating both text and JSON outputs. Add a lightweight integration check that runs `node dist/src/index.js stats --json` after build in a local script.

Acceptance Criteria:
- README includes an example JSON output and a note about `generated_at` timezone (UTC recommended).
- A local integration check script exits 0 when command produces valid JSON.

Files to Create/Modify:
- `README.md` (examples)
- `scripts/check-stats-json.sh` or `test/integration/stats-json-smoke.test.ts`

Verification:
- Manually inspect README example; run integration check script to validate JSON output after build.
