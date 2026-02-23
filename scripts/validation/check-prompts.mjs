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
    if (idx === -1) continue;
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
    [
      "rw-archive.prompt.md",
      [
        "Path resolution (mandatory before Step 0):",
        "Step 0 (Mandatory):",
        "RW_TARGET_ROOT_INVALID",
        "NEXT_COMMAND=<rw-run|rw-archive>",
        "NEXT_COMMAND=rw-run",
      ],
    ],
    [
      "rw-feature.prompt.md",
      ["Step 0 (Mandatory):", "FEATURE_NEED_INSUFFICIENT", "Trigger / Situation", "Out-of-Scope Boundary", "NEXT_COMMAND=rw-plan"],
    ],
    ["rw-new-project.prompt.md", ["Step 0 (Mandatory):", "NEXT_COMMAND=rw-plan"]],
    ["rw-onboard-project.prompt.md", ["Step 0 (Mandatory):", "CODEBASE_SIGNAL_COUNT", "NEXT_COMMAND=rw-feature"]],
    [
      "rw-plan.prompt.md",
      [
        "Step 0 (Mandatory):",
        "PLAN_ID=<id>",
        "PLAN_ARTIFACT_DIR=.ai/plans/<plan_id>/",
        "RESEARCH_FINDINGS_FILE=.ai/plans/<plan_id>/research_findings_<slug>.yaml",
        "PLAN_MODE=<INITIAL|REPLAN|EXTENSION>",
        "TASK_BOOTSTRAP_FILE=.ai/tasks/TASK-00-READBEFORE.md",
        "PLAN_RISK_LEVEL=<LOW|MEDIUM|HIGH>",
        "PLAN_CONFIDENCE=<HIGH|MEDIUM|LOW>",
        "OPEN_QUESTIONS_COUNT=<n>",
        "Test Strategy",
        "[acceptance]",
        "NEXT_COMMAND=rw-run",
      ],
    ],
    [
      "rw-review.prompt.md",
      [
        "Step 0 (Mandatory):",
        "NEXT_COMMAND=",
        "REVIEW_STATUS=",
        "REVIEW_PHASE_NOTE_FILE=",
        "REVIEW_PHASE_PRECHECK_FAIL",
        "Test Strategy",
        "[acceptance]",
        "REVIEW_FINDING TASK-XX <P0|P1|P2>|<file>|<line>|<rule>|<fix>",
        "REVIEW_ISSUE <P0|P1|P2>|<file>|<line>|<rule>|<fix>",
      ],
    ],
    [
      "rw-run.prompt.md",
      [
        "Step 0 (Mandatory):",
        "RW_DOCTOR_AUTORUN_BEGIN",
        "<FEATURES>",
        "VERIFICATION_EVIDENCE <LOCKED_TASK_ID>",
        "RW_SUBAGENT_VERIFICATION_EVIDENCE_MISSING",
        "NEXT_COMMAND=",
        "RW_SUBAGENT_COMPLETION_DELTA_INVALID",
      ],
    ],
  ]);

  const errors = [];

  for (const fileName of rwPromptFiles) {
    const filePath = path.join(promptsDir, fileName);
    const content = await fs.readFile(filePath, "utf8");
    const normalized = content.replace(/\r\n/g, "\n");

    const { fields, error } = parseFrontMatter(fileName, normalized);
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

    requireToken(errors, fileName, normalized, "Language policy reference:");
    for (const token of requiredPerFile.get(fileName) ?? []) {
      requireToken(errors, fileName, normalized, token);
    }
  }

  const contextPath = path.join(repoRoot, ".ai", "CONTEXT.md");
  if (!(await exists(contextPath))) {
    errors.push(".ai/CONTEXT.md: missing file");
  } else {
    const contextBody = await fs.readFile(contextPath, "utf8");
    requireToken(errors, ".ai/CONTEXT.md", contextBody, "`REVIEW_OK`");
    requireToken(errors, ".ai/CONTEXT.md", contextBody, "`FEATURE_MULTI_READY_AUTOSELECTED`");
    requireToken(errors, ".ai/CONTEXT.md", contextBody, "`VERIFICATION_EVIDENCE`");
    requireToken(errors, ".ai/CONTEXT.md", contextBody, "`FEATURE_NEED_INSUFFICIENT`");
  }

  const subagentPromptContracts = new Map([
    [
      path.join(promptsDir, "orchestrator", "rw-orchestrator-feature-phase.subagent.md"),
      [
        "Never call `#tool:agent/runSubagent`",
        "FEATURE_NEED_INSUFFICIENT",
        "Trigger / Situation",
        "Out-of-Scope Boundary",
        "FEATURE_FILE=<path>",
        "FEATURE_STATUS=READY_FOR_PLAN",
      ],
    ],
    [
      path.join(promptsDir, "orchestrator", "rw-orchestrator-plan-phase.subagent.md"),
      [
        "Never call `#tool:agent/runSubagent`",
        "PLAN_ID=<id>",
        "PLAN_ARTIFACT_DIR=<path>",
        "RESEARCH_FINDINGS_FILE=<path>",
        "PLAN_SUMMARY_FILE=<path>",
        "PLAN_FEATURE_FILE=<filename>",
        "PLAN_TASK_RANGE=<TASK-XX~TASK-YY>",
        "PLAN_MODE=<INITIAL|REPLAN|EXTENSION>",
        "TASK_BOOTSTRAP_FILE=<path>",
        "PLAN_RISK_LEVEL=<LOW|MEDIUM|HIGH>",
        "PLAN_CONFIDENCE=<HIGH|MEDIUM|LOW>",
        "OPEN_QUESTIONS_COUNT=<n>",
        "PLANNING_PROFILE_APPLIED=<STANDARD|FAST_TEST>",
        "Test Strategy",
      ],
    ],
  ]);

  for (const [subagentPromptPath, tokens] of subagentPromptContracts.entries()) {
    const relPath = path.relative(repoRoot, subagentPromptPath);
    if (!(await exists(subagentPromptPath))) {
      errors.push(`${relPath}: missing file`);
      continue;
    }
    const promptBody = await fs.readFile(subagentPromptPath, "utf8");
    for (const token of tokens) {
      requireToken(errors, relPath, promptBody, token);
    }
  }

  const orchestratorAgentPath = path.join(repoRoot, ".github", "agents", "rw-orchestrator.agent.md");
  if (!(await exists(orchestratorAgentPath))) {
    errors.push(".github/agents/rw-orchestrator.agent.md: missing file");
  } else {
    const orchestratorAgent = await fs.readFile(orchestratorAgentPath, "utf8");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "rw-orchestrator-feature-phase.subagent.md");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "rw-orchestrator-plan-phase.subagent.md");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "Follow `.github/prompts/rw-run.prompt.md` contract.");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "Follow `.github/prompts/rw-review.prompt.md` contract.");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "RW_REPLAN_TRIGGERED");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "RW_SUBAGENT_VERIFICATION_EVIDENCE_MISSING");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "VERIFICATION_EVIDENCE <LOCKED_TASK_ID>");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "REVIEW_SUMMARY total=0 ok=0 fail=0 escalate=0 skipped=<completed-count>");
    requireToken(errors, ".github/agents/rw-orchestrator.agent.md", orchestratorAgent, "REVIEW_PHASE_NOTE_FILE=none");
  }

  const smokeScriptPath = path.join(repoRoot, "scripts", "rw-smoke-test.sh");
  if (!(await exists(smokeScriptPath))) {
    errors.push("scripts/rw-smoke-test.sh: missing file");
  } else {
    const smokeScript = await fs.readFile(smokeScriptPath, "utf8");
    requireToken(errors, "scripts/rw-smoke-test.sh", smokeScript, "last-result.json");
    requireToken(errors, "scripts/rw-smoke-test.sh", smokeScript, "write_smoke_result_artifacts");
    requireToken(errors, "scripts/rw-smoke-test.sh", smokeScript, "Scenario 1: New Project Flow");
  }

  const ciWorkflowPath = path.join(repoRoot, ".github", "workflows", "rw-smoke-test.yml");
  if (await exists(ciWorkflowPath)) {
    const ciWorkflow = await fs.readFile(ciWorkflowPath, "utf8");
    requireToken(errors, ".github/workflows/rw-smoke-test.yml", ciWorkflow, "node scripts/validation/check-prompts.mjs");
    requireToken(errors, ".github/workflows/rw-smoke-test.yml", ciWorkflow, "./scripts/rw-smoke-test.sh");
    requireToken(errors, ".github/workflows/rw-smoke-test.yml", ciWorkflow, "npm test");
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
