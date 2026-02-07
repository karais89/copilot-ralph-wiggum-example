# TASK-01: Project Initialization

## Dependencies: none

## Description

Initialize the Node.js project with TypeScript support. Set up the basic project structure, configuration files, and install all necessary dependencies.

## Acceptance Criteria

- [ ] `package.json` created with correct metadata, `"type": "module"`, and scripts (`build`, `start`)
- [ ] `tsconfig.json` configured with strict mode, ESM output, and proper paths
- [ ] `.gitignore` includes `node_modules/`, `dist/`, `data/todos.json`
- [ ] Dependencies installed: `commander`, `nanoid`
- [ ] Dev dependencies installed: `typescript`, `@types/node`, `tsx`
- [ ] `src/` directory structure created with placeholder files
- [ ] Project builds without errors (`npm run build`)

## Files to Create/Modify

- `package.json`
- `tsconfig.json`
- `.gitignore`

## Verification

- Run `npm run build` and confirm TypeScript compilation succeeds.
- Run `cat .gitignore` and confirm `node_modules/`, `dist/`, and `data/todos.json` are listed.
- Run `ls src` and confirm the initial source directory structure exists.
