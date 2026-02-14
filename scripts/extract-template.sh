#!/usr/bin/env bash
#
# extract-template.sh
#
# Extracts the Ralph Wiggum orchestration template files into a target directory.
# The extracted files can be dropped into any new project to enable the RW workflow.
#
# Usage:
#   ./scripts/extract-template.sh <target-directory>
#
# Example:
#   ./scripts/extract-template.sh ~/my-new-project
#   cd ~/my-new-project && git init
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argument check ---
if [ $# -lt 1 ]; then
  echo "Usage: $0 <target-directory>"
  echo ""
  echo "Example:"
  echo "  $0 ~/my-new-project"
  exit 1
fi

TARGET="$1"

if [ -d "$TARGET/.github/prompts" ] || [ -d "$TARGET/.ai" ]; then
  echo "⚠️  Target already contains .github/prompts or .ai directories."
  read -r -p "Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# --- Create directory structure ---
echo "📁 Creating directory structure in $TARGET ..."

mkdir -p "$TARGET/.github/prompts"
mkdir -p "$TARGET/scripts"
mkdir -p "$TARGET/.ai/features"
mkdir -p "$TARGET/.ai/templates"
mkdir -p "$TARGET/.ai/tasks"
mkdir -p "$TARGET/.ai/notes"
mkdir -p "$TARGET/.ai/progress-archive"
mkdir -p "$TARGET/.ai/runtime/rw-targets"

# --- Copy prompt files ---
echo "📋 Copying orchestration prompts ..."

cp "$REPO_ROOT/.github/prompts/rw-init.prompt.md"        "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-new-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-onboard-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-doctor.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-feature.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-plan.prompt.md"    "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-run.prompt.md"     "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-review.prompt.md"       "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-archive.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-smoke-test.prompt.md"   "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/RW-INTERACTIVE-POLICY.md"  "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/RW-TARGET-ROOT-RESOLUTION.md" "$TARGET/.github/prompts/"
cp -R "$REPO_ROOT/.github/prompts/smoke" "$TARGET/.github/prompts/"

# --- Copy shared utility scripts ---
echo "🛠️  Copying shared utility scripts ..."
cp "$REPO_ROOT/scripts/rw-resolve-target-root.sh" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/rw-bootstrap-scaffold.sh" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/rw-target-registry.sh" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/validate-smoke-result.sh" "$TARGET/scripts/"
cp "$REPO_ROOT/scripts/check-prompts.mjs" "$TARGET/scripts/"
chmod +x "$TARGET/scripts/rw-resolve-target-root.sh"
chmod +x "$TARGET/scripts/rw-bootstrap-scaffold.sh"
chmod +x "$TARGET/scripts/rw-target-registry.sh"
chmod +x "$TARGET/scripts/validate-smoke-result.sh"

# --- Copy .ai structural files ---
echo "📄 Copying .ai structural files ..."

cp "$REPO_ROOT/.ai/CONTEXT.md"                   "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/GUIDE.md"                     "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/features/FEATURE-TEMPLATE.md" "$TARGET/.ai/features/"
cp "$REPO_ROOT/.ai/features/README.md"           "$TARGET/.ai/features/"
cp "$REPO_ROOT/.ai/templates/CONTEXT-BOOTSTRAP.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/PROJECT-CHARTER-TEMPLATE.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/BOOTSTRAP-FEATURE-TEMPLATE.md" "$TARGET/.ai/templates/"
cp "$REPO_ROOT/.ai/templates/SMOKE-RESULT-SCHEMA.json" "$TARGET/.ai/templates/"

# --- Add .gitkeep to empty directories ---
touch "$TARGET/.ai/tasks/.gitkeep"
touch "$TARGET/.ai/notes/.gitkeep"
touch "$TARGET/.ai/progress-archive/.gitkeep"
touch "$TARGET/.ai/runtime/.gitkeep"
touch "$TARGET/.ai/runtime/rw-targets/.gitkeep"

# --- Summary ---
echo ""
echo "✅ Ralph Wiggum template extracted to: $TARGET"
echo ""
echo "Extracted files:"
echo "  .github/prompts/"
echo "    rw-init.prompt.md"
echo "    rw-new-project.prompt.md"
echo "    rw-onboard-project.prompt.md"
echo "    rw-doctor.prompt.md"
echo "    rw-feature.prompt.md"
echo "    rw-plan.prompt.md"
echo "    rw-run.prompt.md"
echo "    rw-review.prompt.md"
echo "    rw-archive.prompt.md"
echo "    rw-smoke-test.prompt.md"
echo "    RW-INTERACTIVE-POLICY.md"
echo "    RW-TARGET-ROOT-RESOLUTION.md"
echo "    smoke/"
echo "      SMOKE-CONTRACT.md"
echo "      phases/phase-*.md"
echo "      templates/*.subagent.md"
echo "  scripts/"
echo "    rw-resolve-target-root.sh"
echo "    rw-bootstrap-scaffold.sh"
echo "    rw-target-registry.sh"
echo "    validate-smoke-result.sh"
echo "    check-prompts.mjs"
echo "  .ai/"
echo "    CONTEXT.md"
echo "    GUIDE.md"
echo "    features/FEATURE-TEMPLATE.md"
echo "    features/README.md"
echo "    templates/CONTEXT-BOOTSTRAP.md"
echo "    templates/PROJECT-CHARTER-TEMPLATE.md"
echo "    templates/BOOTSTRAP-FEATURE-TEMPLATE.md"
echo "    templates/SMOKE-RESULT-SCHEMA.json"
echo "    tasks/           (empty)"
echo "    notes/           (empty)"
echo "    progress-archive/ (empty)"
echo "    runtime/rw-targets/ (empty)"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open VS Code with Copilot Chat"
echo "  3. Run rw-new-project.prompt.md (integrated init + discovery)"
echo "     - For existing codebases, run rw-onboard-project.prompt.md instead."
echo "     - Existing-codebase path: rw-onboard-project -> rw-feature -> rw-plan."
echo "  4. Run rw-plan.prompt.md to generate bootstrap tasks"
echo "  5. Run rw-run.prompt.md to start the orchestration loop"
echo "  6. Run rw-review.prompt.md after rw-run (batch review)"
echo "  7. Run rw-feature.prompt.md to add another feature (optional)"
echo "  8. Run rw-plan.prompt.md"
echo "  9. Run rw-run.prompt.md"
echo " 10. Run rw-review.prompt.md"
echo " 11. Optional: run rw-doctor.prompt.md if you want standalone preflight diagnostics"
echo " 12. Optional: use rw-init.prompt.md only when scaffold-only setup is needed"
echo " 13. Optional: run rw-smoke-test.prompt.md for end-to-end smoke validation"
