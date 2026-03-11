#!/usr/bin/env bash
# Run-every-session setup: VS Code terminal rename + settings
# Usage: bash setup.sh <branch-name>

set -euo pipefail

BRANCH_NAME="${1:?Usage: setup.sh <branch-name>}"

# --- Ensure VS Code terminal rename setting ---
mkdir -p .vscode
if [ ! -f .vscode/settings.json ]; then
    printf '{\n  "terminal.integrated.tabs.title": "${sequence}"\n}\n' > .vscode/settings.json
    echo "Created .vscode/settings.json with terminal rename setting"
elif ! grep -q 'terminal.integrated.tabs.title' .vscode/settings.json 2>/dev/null; then
    echo "WARNING: .vscode/settings.json exists but missing terminal.integrated.tabs.title"
    echo "Please add: \"terminal.integrated.tabs.title\": \"\${sequence}\""
fi

# --- Rename the VS Code terminal tab ---
printf '\e]2;%s\a' "$BRANCH_NAME"
echo "Terminal renamed to: $BRANCH_NAME"
