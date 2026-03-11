#!/usr/bin/env bash
# Git Worktree Setup Script
# Usage: bash setup.sh <branch-name>
# Creates an isolated git worktree under .worktrees/ at the project root.

set -euo pipefail

BRANCH_NAME="${1:?Usage: setup.sh <branch-name>}"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
WORKTREE_DIR="$PROJECT_ROOT/.worktrees/$BRANCH_NAME"

# --- Safety: ensure .worktrees is git-ignored ---
if ! git check-ignore -q .worktrees 2>/dev/null; then
    echo ".worktrees not in .gitignore — adding it now"
    echo ".worktrees" >> "$PROJECT_ROOT/.gitignore"
    git -C "$PROJECT_ROOT" add .gitignore
    git -C "$PROJECT_ROOT" commit -m "chore: add .worktrees to .gitignore"
fi

# --- Create worktree ---
if [ -d "$WORKTREE_DIR" ]; then
    echo "Worktree already exists at $WORKTREE_DIR — reusing it"
else
    git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME"
    echo "Created worktree at $WORKTREE_DIR"
fi

cd "$WORKTREE_DIR"

# --- Auto-detect and run project setup ---
if [ -f package.json ]; then
    echo "Node.js detected — running npm install"
    npm install
fi

if [ -f Cargo.toml ]; then
    echo "Rust detected — running cargo build"
    cargo build
fi

if [ -f requirements.txt ]; then
    echo "Python detected — running pip install"
    pip install -r requirements.txt
fi

if [ -f pyproject.toml ]; then
    echo "Python (pyproject) detected — running pip install -e ."
    pip install -e .
fi

if [ -f go.mod ]; then
    echo "Go detected — running go mod download"
    go mod download
fi

echo ""
echo "Worktree ready at $WORKTREE_DIR"
echo "Branch: $BRANCH_NAME"
