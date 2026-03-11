---
name: consolidate-changelogs
description: Consolidate per-branch changelog files into CLAUDE.md, then clean up worktrees and merged branches.
user_invocable: true
---

# Consolidate Changelogs

Merges pending `docs/changelogs/*.md` files into CLAUDE.md and cleans up stale git worktrees and merged branches.

---

## When to use

Run this after a batch of branches have been merged to master — typically when multiple changelog files have accumulated in `docs/changelogs/`.

---

## Steps

### 1. Read all pending changelogs

Read every `.md` file in `docs/changelogs/` (skip `.gitkeep`). For each file, extract:

- **Change Log entry** — the "What changed" and "Technical details" sections, to be condensed into the CLAUDE.md `## Change Log` section.
- **CLAUDE.md updates** — specific items that need to be applied to other CLAUDE.md sections (Key Concepts, Known Gotchas, Database, API Endpoints, etc.).

If there are no changelog files, stop and tell the user there's nothing to consolidate.

### 2. Apply CLAUDE.md updates to their target sections

For each changelog's `## CLAUDE.md updates` section, apply the requested changes to the relevant parts of CLAUDE.md:

- **Key Concepts**: Update descriptions, add/remove bullets
- **Known Gotchas**: Add new gotchas, update or remove outdated ones
- **Database**: Update migration count and list
- **API Endpoints**: Add/update/remove endpoints
- **Project Structure**: Update if files/directories changed
- **Development Commands**: Update test counts, new commands
- **Environment Variables**: Add new env vars
- **Any other section** mentioned in the update items

Be precise — match the existing style and formatting of each section.

### 3. Condense changelog entries into the Change Log section

Add each branch's changes as a **one-line bullet** in the `### Earlier changes` list. Format:

```
- **Short title** (`branch-name`): One-sentence summary of what changed. Key migration or file if notable.
```

If a previous full entry (with "What changed" and "Technical details" subsections) exists for a branch that's now being consolidated, replace it with a condensed one-liner in the `### Earlier changes` list.

Update the date range in the `### Earlier changes` header if needed.

### 4. Delete processed changelog files

Remove all `.md` files from `docs/changelogs/` that were just consolidated. Preserve `.gitkeep`. If `.gitkeep` was accidentally deleted, recreate it with `touch`.

### 5. Clean up git worktrees

```bash
git worktree list
```

For each worktree that corresponds to a merged branch:

1. `git worktree remove <path>` — use `--force` only if the worktree contains just build artifacts (e.g., `tsconfig.app.tsbuildinfo`, `node_modules`, `__pycache__`). If it has real modified files, warn the user.
2. `git worktree prune` to clean stale references.
3. Remove empty parent directories under `.worktrees/` (e.g., `.worktrees/feat/`, `.worktrees/fix/`).

### 6. Delete merged local branches

List local branches (`git branch`) and delete ones that have been merged to master:

```bash
git branch -d <branch-name>
```

If `-d` fails (not merged), do NOT force delete — warn the user instead.

### 7. Verify

- `docs/changelogs/` contains only `.gitkeep`
- `git worktree list` shows only the main worktree
- `git branch` shows only `master` (or expected long-lived branches)
- CLAUDE.md changes are coherent and correctly formatted

---

## Rules

- **Never lose information.** Every changelog entry must appear in CLAUDE.md after consolidation.
- **Condense, don't copy.** Full changelog entries become one-line bullets. Technical details are only preserved if they affect how future sessions work (gotchas, patterns, env vars).
- **Match existing style.** Follow the formatting conventions already in CLAUDE.md.
- **Don't force-delete branches.** If `git branch -d` fails, the branch isn't fully merged — ask the user.
- **Don't force-remove worktrees with real changes.** Build artifacts are fine to force-remove; modified source files are not.
