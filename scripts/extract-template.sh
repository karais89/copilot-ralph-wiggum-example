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
mkdir -p "$TARGET/.ai/tasks"
mkdir -p "$TARGET/.ai/notes"
mkdir -p "$TARGET/.ai/progress-archive"
mkdir -p "$TARGET/.ai/runtime/rw-targets"

# --- Copy prompt files ---
echo "📋 Copying orchestration prompts ..."

cp "$REPO_ROOT/.github/prompts/rw-init.prompt.md"        "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-new-project.prompt.md" "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-doctor.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-feature.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-plan.prompt.md"    "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-run.prompt.md"     "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-review.prompt.md"       "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/rw-archive.prompt.md"      "$TARGET/.github/prompts/"
cp "$REPO_ROOT/.github/prompts/RW-INTERACTIVE-POLICY.md"  "$TARGET/.github/prompts/"

# --- Copy shared utility scripts ---
echo "🛠️  Copying shared utility scripts ..."
cp "$REPO_ROOT/scripts/rw-resolve-target-root.sh" "$TARGET/scripts/"
chmod +x "$TARGET/scripts/rw-resolve-target-root.sh"

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
echo "    rw-doctor.prompt.md"
echo "    rw-feature.prompt.md"
echo "    rw-plan.prompt.md"
echo "    rw-run.prompt.md"
echo "    rw-review.prompt.md"
echo "    rw-archive.prompt.md"
echo "    RW-INTERACTIVE-POLICY.md"
echo "  scripts/"
echo "    rw-resolve-target-root.sh"
echo "  .ai/"
echo "    CONTEXT.md"
echo "    GUIDE.md"
echo "    features/FEATURE-TEMPLATE.md"
echo "    features/README.md"
echo "    tasks/           (empty)"
echo "    notes/           (empty)"
echo "    progress-archive/ (empty)"
echo "    runtime/rw-targets/ (empty)"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open VS Code with Copilot Chat"
echo "  3. Run rw-new-project.prompt.md (integrated init + discovery)"
echo "  4. Run rw-doctor.prompt.md before autonomous runs"
echo "  5. Run rw-feature.prompt.md to create a feature spec"
echo "  6. Run rw-plan.prompt.md to generate tasks"
echo "  7. Run rw-doctor.prompt.md again before rw-run"
echo "  8. Run rw-run.prompt.md to start the orchestration loop"
echo "  9. Run rw-review.prompt.md after rw-run (batch review)"
echo " 10. Optional: use rw-init.prompt.md only when scaffold-only setup is needed"
