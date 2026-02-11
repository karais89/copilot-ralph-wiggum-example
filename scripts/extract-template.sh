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
    exit 0
  fi
fi

# --- Create directory structure ---
echo "📁 Creating directory structure in $TARGET ..."

mkdir -p "$TARGET/.github/prompts"
mkdir -p "$TARGET/.ai/features"
mkdir -p "$TARGET/.ai/tasks"
mkdir -p "$TARGET/.ai/notes"
mkdir -p "$TARGET/.ai/progress-archive"

# --- Copy prompt files ---
echo "📋 Copying orchestration prompts ..."

cp "$REPO_ROOT/.github/prompts/rw-init.prompt.md"        "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-new-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-feature.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-plan-lite.prompt.md"    "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-plan-strict.prompt.md"  "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-run-lite.prompt.md"     "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-run-strict.prompt.md"   "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-archive.prompt.md"      "$TARGET/.github/prompts/"

# --- Copy .ai structural files ---
echo "📄 Copying .ai structural files ..."

cp "$REPO_ROOT/.ai/CONTEXT.md"                   "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/GUIDE.md"                     "$TARGET/.ai/"
cp "$REPO_ROOT/.ai/features/FEATURE-TEMPLATE.md" "$TARGET/.ai/features/"
cp "$REPO_ROOT/.ai/features/README.md"           "$TARGET/.ai/features/"

# --- Add .gitkeep to empty directories ---
touch "$TARGET/.ai/tasks/.gitkeep"
touch "$TARGET/.ai/notes/.gitkeep"
touch "$TARGET/.ai/progress-archive/.gitkeep"

# --- Summary ---
echo ""
echo "✅ Ralph Wiggum template extracted to: $TARGET"
echo ""
echo "Extracted files:"
echo "  .github/prompts/"
echo "    rw-init.prompt.md"
echo "    rw-new-project.prompt.md"
echo "    rw-feature.prompt.md"
echo "    rw-plan-lite.prompt.md"
echo "    rw-plan-strict.prompt.md"
echo "    rw-run-lite.prompt.md"
echo "    rw-run-strict.prompt.md"
echo "    rw-archive.prompt.md"
echo "  .ai/"
echo "    CONTEXT.md"
echo "    GUIDE.md"
echo "    features/FEATURE-TEMPLATE.md"
echo "    features/README.md"
echo "    tasks/           (empty)"
echo "    notes/           (empty)"
echo "    progress-archive/ (empty)"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open VS Code with Copilot Chat"
echo "  3. Run rw-new-project.prompt.md (integrated init + discovery)"
echo "  4. Run rw-feature.prompt.md to create a feature spec"
echo "  5. Run rw-plan-lite.prompt.md (or strict) to generate tasks"
echo "  6. Run rw-run-lite.prompt.md (or strict) to start the orchestration loop"
echo "  7. Optional: use rw-init.prompt.md only when scaffold-only setup is needed"
