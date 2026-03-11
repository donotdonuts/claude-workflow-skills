---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees under .worktrees/ at the project root
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

> **Note:** Shell scripts referenced below are in the same directory as this SKILL.md. Use the resolved path of this skill to construct absolute paths to co-located scripts.

## Directory

**Always use `.worktrees/` at the project root.** No other location. No asking the user. Create it if it doesn't exist.

## Setup

Run the setup script with the desired branch name:

```bash
bash <skill-dir>/setup.sh <branch-name>
```

The script handles: gitignore safety check, worktree creation, and auto-detected project setup (Node.js, Rust, Python, Go). Read the script for implementation details.

After setup, verify with a baseline test run (use the project-appropriate command: `pytest`, `npm test`, `cargo test`, `go test ./...`).

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready:
```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `.worktrees/` doesn't exist | Script creates it and verifies ignored |
| Directory not ignored | Script auto-adds to .gitignore + commits |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Script skips dependency install |
| Branch is `main`/`master`/`dev` | Refuse — worktrees are for feature branches only |

## Common Mistakes

- **Skipping ignore verification** — Worktree contents get tracked. Script handles this automatically.
- **Using wrong directory** — Always `.worktrees/` at project root.
- **Proceeding with failing tests** — Report failures, get permission first.
- **Hardcoding setup commands** — Script auto-detects from project files.
- **Creating worktrees for `main`/`master`/`dev`** — Worktree space is for feature branches only. Work on protected branches directly in the main checkout.

## Red Flags

**Never:**
- Create worktree without verifying `.worktrees` is ignored
- Create worktrees outside `.worktrees/`
- Create worktrees for `main`, `master`, or `dev` branches — worktree space is reserved for feature branches only
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Use `.worktrees/` at the project root
- Run the setup script (or follow its logic)
- Verify clean test baseline

## Integration

**Called by:** run-every-session (Phase 1b), any skill needing isolated workspace.

**Pairs with:** consolidate-changelogs (cleanup after work complete).
