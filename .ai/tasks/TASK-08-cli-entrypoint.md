# TASK-08: CLI Entry Point

## Status: pending

## Dependencies: TASK-04, TASK-05, TASK-06, TASK-07

## Description

Wire up all commands into the main CLI entry point using Commander.js. Configure the program name, version, description, and register all subcommands.

## Acceptance Criteria

- [ ] `src/index.ts` sets up Commander with program name `todo`, version from package.json
- [ ] All 4 commands registered: `add`, `list`, `done`, `delete`
- [ ] `todo --help` shows all available commands
- [ ] `todo <command> --help` shows command-specific help
- [ ] Add a shebang line `#!/usr/bin/env node` for direct execution
- [ ] `package.json` `bin` field points to the compiled entry point

## Files to Create/Modify

- `src/index.ts`
- `package.json` (add `bin` field)
