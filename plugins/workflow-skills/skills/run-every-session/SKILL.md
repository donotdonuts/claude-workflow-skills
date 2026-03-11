---
name: run-every-session
description: Auto-invoked at session start. Renames VS Code terminal, defers worktree creation to after planning, and writes per-branch changelog on wrap-up.
---

# Session Workflow

Auto-invoked at the start of every session. Three phases: **Session Start**, **Implementation Start**, and **Wrap-Up**.

> **Note:** Shell scripts referenced below are in the same directory as this SKILL.md. Use the resolved path of this skill to construct absolute paths to co-located scripts.

---

## Phase 1a: Session Start (before planning)

Run immediately when invoked. Do NOT create a worktree or feature branch yet.

1. **Rename the VS Code terminal** by running the setup script with a placeholder name:
   ```bash
   bash <skill-dir>/setup.sh "claude-session"
   ```
   If `.vscode/settings.json` already exists with other settings, read it and add the `terminal.integrated.tabs.title` key manually if missing (don't overwrite).

2. Proceed with understanding the task, entering plan mode, etc. The worktree is created later.

---

## Phase 1b: Implementation Start (after planning is approved)

Once the plan is approved and the branch name is known:

1. Invoke `/workflow-skills:using-git-worktrees` to create the feature branch and worktree.
2. Branch naming: `feat/`, `fix/`, `chore/`, or `refactor/` + short description.
3. All work happens in the worktree directory. NEVER commit to `main`/`master`.
4. **Re-rename the terminal** to the actual branch name:
   ```bash
   printf '\e]2;%s\a' "<branch-name>"
   ```

---

## Phase 2: Wrap-Up — Write Per-Branch Log (MANDATORY)

> **This phase is MANDATORY.** Claude MUST write the changelog before ending any session where code was changed. Do not wait for the user to ask — proactively write the changelog after the final commit. If the user says "wrap up", "done", "that's it", or signals the task is complete, write the changelog immediately. If the session is ending and no changelog has been written yet, write it before responding to the user's final message.

When done, write a log file capturing what CLAUDE.md needs to know about this branch's changes:

```
docs/changelogs/<YYYY-MM-DD>-<branch-name>.md
```

For example: `docs/changelogs/2026-02-18-feat-api-rate-limiting.md`

**Filename rules:** Date first (ISO format), then branch name with slashes replaced by hyphens. This ensures chronological sorting and unique names even if a branch is reused.

### Entry format

```markdown
# [Short Title]
**Date:** YYYY-MM-DD
**Branch:** `<branch-name>`

## What changed (plain English)
[2-4 sentences. Explain the problem and solution as if talking to a non-developer. Simple language, no jargon.]

## Technical details
[What files changed, approach taken, architectural decisions, gotchas, follow-ups. Be specific but concise.]

## CLAUDE.md updates
[List specific additions/changes needed in CLAUDE.md: new gotchas, new endpoints, architecture changes, new env vars, updated project structure, etc. Only include items that future sessions need to know. Leave empty if no CLAUDE.md updates are needed.]
```

### Rules

- **Simple explanation FIRST, technical SECOND.** Non-negotiable.
- Simple section: zero coding knowledge required to understand.
- Technical section: useful to a dev picking this up for the first time.
- CLAUDE.md updates section: only things that affect how future sessions work with the codebase (gotchas, new patterns, changed APIs, new env vars, etc.). Skip if nothing is relevant.
- Note trade-offs, limitations, and follow-up tasks.
- Create the `docs/changelogs/` directory if it doesn't exist.
- **Do NOT update CLAUDE.md directly.** Log files accumulate and are consolidated at the end of a batch.

### Consolidation

CLAUDE.md is updated **only at the end of a batch of work** (when the user explicitly asks, or after multiple branches are complete). To consolidate:

1. Read all pending log files in `docs/changelogs/`.
2. Merge their Change Log entries into the `## Change Log` section of CLAUDE.md.
3. Apply any `## CLAUDE.md updates` items to the relevant sections of CLAUDE.md (gotchas, endpoints, structure, etc.).
4. Delete the individual log files after consolidation.

### Example

File: `docs/changelogs/2026-02-17-feat-api-rate-limiting.md`

```markdown
# Add rate limiting to API
**Date:** 2026-02-17
**Branch:** `feat/api-rate-limiting`

## What changed (plain English)
Too many requests from some users were slowing the API for everyone. We added a per-user limit — if someone sends too many requests in a minute, they get a "slow down" response instead of crashing the server.

## Technical details
- Added `express-rate-limit` middleware in `src/middleware/rateLimiter.ts`
- Sliding window: 100 req/min general, 20/min auth endpoints
- Redis-backed store for multi-instance consistency
- Returns 429 with `{ error: "rate_limit_exceeded", retryAfter }`
- Tests in `src/middleware/__tests__/rateLimiter.test.ts`
- **Follow-up:** Currently IP-based only; need per-authenticated-user limits.

## CLAUDE.md updates
- **New gotcha:** Rate limiting is IP-based (not per-user). `express-rate-limit` middleware in `src/middleware/rateLimiter.ts`. 100 req/min general, 20/min auth.
- **New env var:** `RATE_LIMIT_WINDOW_MS` (optional, defaults to 60000).
```

---

## Task Checklist

- [ ] VS Code terminal renamed at session start
- [ ] Plan approved before creating worktree
- [ ] Feature branch created with descriptive name
- [ ] Terminal re-renamed to branch name
- [ ] All work done in worktree directory
- [ ] Code complete and tested
- [ ] Changes committed
- [ ] **MANDATORY:** Log entry written to `docs/changelogs/<YYYY-MM-DD>-<branch-name>.md` and committed

---

## Edge Cases

- **Multiple tasks/session:** Separate branch + worktree + changelog file per task.
- **Resuming:** If worktree exists, `cd` into it.
- **Cleanup:** `git worktree remove ../worktrees/<branch-name>` after merge.
- **Simple tasks (no planning needed):** Create the worktree immediately — skip Phase 1a/1b split. Use your judgment.
- **No code changes:** If the session was research/exploration only (no commits), skip the changelog. The changelog is mandatory only when code was committed.
- **Forgot to write changelog:** If the user asks a new question or signals they're moving on and you haven't written the changelog yet, write it immediately before addressing the new topic.
- **Stop hook enforcement:** The Stop hook in the plugin's `hooks/hooks.json` runs `check-changelog.sh` every time Claude finishes responding. It blocks stopping if an active feature branch has commits but no changelog file. This is the safety net — write the changelog proactively so the hook never needs to fire.
