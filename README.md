# Claude Workflow Skills

A Claude Code plugin marketplace providing 6 workflow skills for session management, git worktrees, security, brainstorming, notifications, and changelog management.

## Skills

| Skill | Description |
|-------|-------------|
| `run-every-session` | Auto-invoked at session start. Renames terminal, defers worktree creation to after planning, writes per-branch changelogs on wrap-up. |
| `using-git-worktrees` | Creates isolated git worktrees under `.worktrees/` for feature branch work. Auto-detects project type and installs dependencies. |
| `security` | Security & privacy guard. Enforces best practices for secrets, input validation, auth, dependencies, logging, and more. Includes automated scan script. |
| `brainstorming` | Collaborative design process before implementation. Explores intent, proposes approaches, validates design before any code is written. |
| `claude-code-notify` | Sets up audio/visual notifications (bell, sound, voice, OS notification) for when Claude finishes responding. |
| `consolidate-changelogs` | Merges per-branch changelog files into CLAUDE.md and cleans up worktrees and merged branches. |

## Installation

### From GitHub (as a marketplace)

```bash
# Inside Claude Code:
/plugin marketplace add donotdonuts/claude-workflow-skills

# Then install the plugin:
/plugin install workflow-skills@lc-workflow
```

### From a local directory

```bash
# Inside Claude Code:
/plugin marketplace add /path/to/claude-workflow-skills

# Then install the plugin:
/plugin install workflow-skills@lc-workflow
```

### Auto-install for a project

Add to your project's `.claude/settings.json` so collaborators get prompted automatically:

```json
{
  "extraKnownMarketplaces": {
    "lc-workflow": {
      "source": {
        "source": "github",
        "repo": "donotdonuts/claude-workflow-skills"
      }
    }
  },
  "enabledPlugins": {
    "workflow-skills@lc-workflow": true
  }
}
```

## Usage

Once installed, skills are available as slash commands:

```
/workflow-skills:run-every-session
/workflow-skills:using-git-worktrees
/workflow-skills:security
/workflow-skills:brainstorming
/workflow-skills:claude-code-notify
/workflow-skills:consolidate-changelogs
```

## Hooks

The plugin includes two hooks:

- **SessionStart**: Reminds Claude to invoke the `run-every-session` skill at the start of every session.
- **Stop**: Runs `check-changelog.sh` to block stopping if a feature branch has commits but no changelog file.

## Workflow Overview

1. **Session starts** → `run-every-session` renames the terminal
2. **User describes task** → `brainstorming` explores the design space
3. **Plan approved** → `using-git-worktrees` creates an isolated workspace
4. **During development** → `security` enforces best practices
5. **Task complete** → `run-every-session` Phase 2 writes the changelog
6. **Batch complete** → `consolidate-changelogs` merges everything into CLAUDE.md

## Structure

```
claude-workflow-skills/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog
├── plugins/
│   └── workflow-skills/          # The plugin
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin manifest
│       ├── skills/               # 6 skills with SKILL.md + scripts
│       │   ├── run-every-session/
│       │   ├── using-git-worktrees/
│       │   ├── security/
│       │   ├── brainstorming/
│       │   ├── claude-code-notify/
│       │   └── consolidate-changelogs/
│       └── hooks/
│           └── hooks.json
└── README.md
```

## Requirements

- Claude Code CLI
- Git
- Bash
- Python 3 (for `check-changelog.sh` JSON parsing)

## License

MIT
