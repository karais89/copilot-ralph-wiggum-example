#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";

async function exists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function resolveRepoRoot(startDir) {
  let dir = path.resolve(startDir);
  while (true) {
    if (await exists(path.join(dir, ".github", "prompts"))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      throw new Error("Could not find repository root with .github/prompts");
    }
    dir = parent;
  }
}

function parseFrontMatter(filePath, content) {
  if (!content.startsWith("---\n")) {
    return { error: `${filePath}: missing front matter opening ---` };
  }

  const end = content.indexOf("\n---\n", 4);
  if (end === -1) {
    return { error: `${filePath}: missing front matter closing ---` };
  }

  const block = content.slice(4, end).trim();
  const fields = new Map();
  for (const line of block.split("\n")) {
    const idx = line.indexOf(":");
    if (idx === -1) {
      continue;
    }
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim().replace(/^"(.*)"$/, "$1");
    fields.set(key, value);
  }

  return { fields };
}

function requireToken(errors, filePath, content, token) {
  if (!content.includes(token)) {
    errors.push(`${filePath}: missing token "${token}"`);
  }
}

async function main() {
  const repoRoot = await resolveRepoRoot(process.cwd());
  const promptsDir = path.join(repoRoot, ".github", "prompts");
  const files = await fs.readdir(promptsDir);
  const rwPromptFiles = files
    .filter((name) => /^rw-.*\.prompt\.md$/.test(name))
    .sort();

  const requiredPerFile = new Map([
    ["rw-archive.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=rw-run"]],
    ["rw-doctor.prompt.md", ["Step 0 (Mandatory):", "RW_DOCTOR_PASS", "RW_DOCTOR_BLOCKED", "NEXT_COMMAND=rw-run"]],
    ["rw-feature.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=rw-plan"]],
    ["rw-init.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND="]],
    ["rw-new-project.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=rw-plan"]],
    ["rw-onboard-project.prompt.md", ["Step 0 (Mandatory):", "CODEBASE_SIGNAL_COUNT", "NEXT_COMMAND=rw-feature"]],
    ["rw-plan.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=rw-run"]],
    ["rw-review.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=", "REVIEW_STATUS=", "REVIEW_PHASE_NOTE_FILE="]],
    ["rw-run.prompt.md", ["Step 0 (Mandatory):", "RW_DOCTOR_AUTORUN_BEGIN", "NEXT_COMMAND=", "RW_SUBAGENT_COMPLETION_DELTA_INVALID"]],
    ["rw-smoke-test.prompt.md", ["SMOKE_TEST_PASS", "SMOKE_TEST_FAIL", "$PROMPT_ROOT/smoke/SMOKE-CONTRACT.md"]],
  ]);

  const errors = [];

  for (const fileName of rwPromptFiles) {
    const filePath = path.join(promptsDir, fileName);
    const content = await fs.readFile(filePath, "utf8");

    const { fields, error } = parseFrontMatter(fileName, content);
    if (error) {
      errors.push(error);
      continue;
    }

    const expectedName = fileName.replace(".prompt.md", "");
    const nameField = fields.get("name");
    if (!nameField) {
      errors.push(`${fileName}: front matter missing "name"`);
    } else if (nameField !== expectedName) {
      errors.push(`${fileName}: front matter name "${nameField}" != expected "${expectedName}"`);
    }

    for (const key of ["description", "agent"]) {
      if (!fields.get(key)) {
        errors.push(`${fileName}: front matter missing "${key}"`);
      }
    }

    requireToken(errors, fileName, content, "Language policy reference:");
    for (const token of requiredPerFile.get(fileName) ?? []) {
      requireToken(errors, fileName, content, token);
    }
  }

  const smokeContractPath = path.join(promptsDir, "smoke", "SMOKE-CONTRACT.md");
  if (!(await exists(smokeContractPath))) {
    errors.push(".github/prompts/smoke/SMOKE-CONTRACT.md: missing file");
  } else {
    const smokeContract = await fs.readFile(smokeContractPath, "utf8");
    requireToken(errors, ".github/prompts/smoke/SMOKE-CONTRACT.md", smokeContract, "Result artifact contract");
    requireToken(errors, ".github/prompts/smoke/SMOKE-CONTRACT.md", smokeContract, "last-result.json");
    requireToken(errors, ".github/prompts/smoke/SMOKE-CONTRACT.md", smokeContract, "last-result.md");
  }

  const requiredSmokeFiles = [
    path.join(promptsDir, "smoke", "phases", "phase-01-new-project.md"),
    path.join(promptsDir, "smoke", "phases", "phase-08-review-2.md"),
    path.join(promptsDir, "smoke", "templates", "run-task.subagent.md"),
  ];
  for (const requiredFile of requiredSmokeFiles) {
    if (!(await exists(requiredFile))) {
      errors.push(`${path.relative(repoRoot, requiredFile)}: missing file`);
    }
  }

  if (errors.length > 0) {
    console.error("PROMPT_INTEGRITY_FAIL");
    for (const err of errors) {
      console.error(`- ${err}`);
    }
    process.exit(1);
  }

  console.log("PROMPT_INTEGRITY_OK");
  console.log(`checked_files=${rwPromptFiles.length}`);
}

main().catch((err) => {
  console.error("PROMPT_INTEGRITY_FAIL");
  console.error(`- unexpected error: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
});
