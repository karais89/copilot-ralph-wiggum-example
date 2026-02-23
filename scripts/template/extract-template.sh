#!/usr/bin/env bash
#
# extract-template.sh
#
# Extracts the Ralph Wiggum orchestration template files into a target directory.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <target-directory>"
  echo ""
  echo "Example:"
  echo "  $0 ~/my-new-project"
  exit 1
fi

TARGET="$1"

if [ -d "$TARGET/.github/prompts" ] || [ -d "$TARGET/.github/agents" ] || [ -d "$TARGET/.ai" ]; then
  echo "⚠️  Target already contains .github/prompts, .github/agents, or .ai directories."
  read -r -p "Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

echo "📁 Creating directory structure in $TARGET ..."

mkdir -p "$TARGET/.github/prompts"
mkdir -p "$TARGET/.github/prompts/orchestrator"
mkdir -p "$TARGET/.github/prompts/shared"
mkdir -p "$TARGET/.github/agents"
mkdir -p "$TARGET/scripts"
mkdir -p "$TARGET/scripts/orchestration"
mkdir -p "$TARGET/scripts/validation"
mkdir -p "$TARGET/.ai/features"
mkdir -p "$TARGET/.ai/templates"
mkdir -p "$TARGET/.ai/tasks"
mkdir -p "$TARGET/.ai/notes"
mkdir -p "$TARGET/.ai/progress-archive"
mkdir -p "$TARGET/.ai/runtime/rw-targets"

echo "📋 Copying orchestration prompts ..."

cp "$REPO_ROOT/.github/prompts/rw-new-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-onboard-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-feature.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-plan.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-run.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-review.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-archive.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/orchestrator/rw-orchestrator-feature-phase.subagent.md" "$TARGET/.github/prompts/orchestrator/"
cp "$REPO_ROOT/.github/prompts/orchestrator/rw-orchestrator-plan-phase.subagent.md" "$TARGET/.github/prompts/orchestrator/"
cp "$REPO_ROOT/.github/prompts/shared/RW-TARGET-ROOT-RESOLUTION.md" "$TARGET/.github/prompts/shared/"
cp "$REPO_ROOT/.github/agents/rw-orchestrator.agent.md" "$TARGET/.github/agents/"

echo "🛠️  Copying shared utility scripts ..."

cp "$REPO_ROOT/scripts/orchestration/rw-resolve-target-root.sh" "$TARGET/scripts/orchestration/"
cp "$REPO_ROOT/scripts/orchestration/rw-bootstrap-scaffold.sh" "$TARGET/scripts/orchestration/"
cp "$REPO_ROOT/scripts/rw" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/rw-smoke-test.sh" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/validation/validate-smoke-result.sh" "$TARGET/scripts/validation/"
cp "$REPO_ROOT/scripts/validation/check-prompts.mjs" "$TARGET/scripts/validation/"

chmod +x "$TARGET/scripts/orchestration/rw-resolve-target-root.sh"
chmod +x "$TARGET/scripts/orchestration/rw-bootstrap-scaffold.sh"
chmod +x "$TARGET/scripts/rw"
chmod +x "$TARGET/scripts/rw-smoke-test.sh"
chmod +x "$TARGET/scripts/validation/validate-smoke-result.sh"

echo "📄 Copying .ai structural files ..."

cp "$REPO_ROOT/.ai/CONTEXT.md" "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/GUIDE.md" "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/features/FEATURE-TEMPLATE.md" "$TARGET/.ai/features/"
cp "$REPO_ROOT/.ai/features/README.md" "$TARGET/.ai/features/"
cp "$REPO_ROOT/.ai/templates/CONTEXT-BOOTSTRAP.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/PROJECT-CHARTER-TEMPLATE.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/SMOKE-RESULT-SCHEMA.json" "$TARGET/.ai/templates/"

touch "$TARGET/.ai/tasks/.gitkeep"
touch "$TARGET/.ai/notes/.gitkeep"
touch "$TARGET/.ai/progress-archive/.gitkeep"
touch "$TARGET/.ai/runtime/.gitkeep"
touch "$TARGET/.ai/runtime/rw-targets/.gitkeep"

echo ""
echo "✅ Ralph Wiggum template extracted to: $TARGET"
echo ""
echo "Extracted files:"
echo "  .github/agents/"
echo "    rw-orchestrator.agent.md"
echo "  .github/prompts/"
echo "    rw-new-project.prompt.md"
echo "    rw-onboard-project.prompt.md"
echo "    rw-feature.prompt.md"
echo "    rw-plan.prompt.md"
echo "    rw-run.prompt.md"
echo "    rw-review.prompt.md"
echo "    rw-archive.prompt.md"
echo "    orchestrator/rw-orchestrator-feature-phase.subagent.md"
echo "    orchestrator/rw-orchestrator-plan-phase.subagent.md"
echo "    shared/RW-TARGET-ROOT-RESOLUTION.md"
echo "  scripts/"
echo "    orchestration/rw-resolve-target-root.sh"
echo "    orchestration/rw-bootstrap-scaffold.sh"
echo "    rw"
echo "    rw-smoke-test.sh"
echo "    validation/validate-smoke-result.sh"
echo "    validation/check-prompts.mjs"
echo "  .ai/"
echo "    CONTEXT.md"
echo "    GUIDE.md"
echo "    features/FEATURE-TEMPLATE.md"
echo "    features/README.md"
echo "    templates/CONTEXT-BOOTSTRAP.md"
echo "    templates/PROJECT-CHARTER-TEMPLATE.md"
echo "    templates/BOOTSTRAP-FEATURE-TEMPLATE.md"
echo "    templates/SMOKE-RESULT-SCHEMA.json"
echo "    tasks/ (empty)"
echo "    notes/ (empty)"
echo "    progress-archive/ (empty)"
echo "    runtime/rw-targets/ (empty)"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open VS Code with Copilot Chat"
echo "  3. Run rw-orchestrator from Agent Picker (optional arg: '--h <feature-summary>')"
echo "  4. Manual flow: rw-new-project -> rw-plan -> rw-run -> rw-review"
echo "     - Existing-codebase path: rw-onboard-project -> rw-feature -> rw-plan"
echo "     - Helper: ./scripts/rw next"
echo "     - Prompt integrity check: node ./scripts/validation/check-prompts.mjs"
