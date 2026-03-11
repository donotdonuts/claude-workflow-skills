---
name: claude-code-notify
description: "Set up audio/visual notifications for Claude Code so you get alerted when Claude finishes responding or needs your input. Use this skill when the user wants to: add notification sounds to Claude Code, get alerted when Claude is waiting, set up hooks for desktop notifications, configure bell/sound/voice/OS notifications on Stop or Notification events, or stop watching the terminal while Claude works. Covers setup of hooks in settings.json, the notify.sh script, and customization of notification modes (bell, sound, voice, osnotify)."
---

# Claude Code Input Notification Hook

Set up notifications so Claude Code rings/alerts you whenever it finishes responding and is waiting for your input.

> **Note:** The notification script referenced below is in the same directory as this SKILL.md. Use the resolved path of this skill to construct absolute paths to co-located scripts.

## Overview

Uses Claude Code's **native hooks system** to fire a notification script on two lifecycle events:

| Hook Event | When It Fires |
|---|---|
| `Stop` | When Claude finishes its response — **the primary trigger** |
| `Notification` | When Claude sends alerts (permission prompts, idle prompts) |

## Setup Steps

### Step 1: Install the notification script

Copy the template script to the hooks directory:

```bash
mkdir -p ~/.claude/hooks
cp <skill-dir>/notify.sh ~/.claude/hooks/notify.sh
chmod +x ~/.claude/hooks/notify.sh
```

The script source is at `<skill-dir>/notify.sh`. Read it if you need to review or customize the implementation.

### Step 2: Add hooks to settings.json

Merge the following into `~/.claude/settings.json` (global) or `.claude/settings.json` (per-project):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/notify.sh stop",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/notify.sh notification",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Important:** If the user already has hooks in their settings.json, merge these entries into the existing `hooks` object — do NOT overwrite existing hooks.

### Step 3: Restart Claude Code

Hooks are snapshotted at session startup. The user must restart their Claude Code session for new hooks to take effect.

## Customization

The notification mode is controlled via environment variables (add to `~/.bashrc`, `~/.zshrc`, or shell profile):

| Variable | Values | Default | Description |
|---|---|---|---|
| `CLAUDE_NOTIFY_MODE` | `bell`, `sound`, `voice`, `osnotify` | `bell` | Notification type |
| `CLAUDE_NOTIFY_SOUND` | File path | (OS default) | Custom sound file path |
| `CLAUDE_NOTIFY_VOICE_MSG` | String | `"Claude is waiting for your input"` | TTS message for voice mode |

### Mode Details

- **`bell`** — Terminal bell (`\a`). Works everywhere, depends on terminal settings.
- **`sound`** — Plays audio file via `afplay` (macOS) / `paplay`/`aplay` (Linux). Falls back to bell.
- **`voice`** — TTS via `say` (macOS) / `espeak`/`spd-say` (Linux). Falls back to bell.
- **`osnotify`** — OS notification popup via `osascript` (macOS) / `notify-send` (Linux). Also plays bell.

## Troubleshooting

- **No sound?** Test `printf '\a'`. Check terminal prefs. Try `sound` or `osnotify` mode.
- **Hooks not loading?** Run `/hooks` in Claude Code. Verify JSON. Restart session.
- **Too quiet?** Use `osnotify` or `voice` mode.
