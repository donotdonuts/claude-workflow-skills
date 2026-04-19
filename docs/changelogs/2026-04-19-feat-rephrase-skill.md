# Add /rephrase skill for native-English phrasing practice
**Date:** 2026-04-19
**Branch:** `feat/rephrase-skill`

## What changed (plain English)
Added a new skill to the workflow-skills plugin. When the user types `/rephrase`, Claude first restates the user's message in natural, native-English phrasing, points out 2–3 specific vocabulary or grammar upgrades, and then — in the same response — goes on to actually do what the user asked. It's a vocabulary-building tool for non-native English speakers, not a prompt-clarification step. The skill never auto-fires; it only runs when explicitly invoked.

## Technical details
- New file: `plugins/workflow-skills/skills/rephrase/SKILL.md`
- Frontmatter description is explicit about (a) manual invocation only and (b) the requirement to answer in the same response. This matters because skill descriptions are what the harness uses to decide when/how to invoke.
- Skill spec includes a **CRITICAL** section warning the agent not to stop after the rephrase block. Earlier iteration of the skill body was too subtle and would have let the agent treat the rephrase as a full response.
- Output format: quoted original → rephrased version → vocab upgrade bullets → `---` divider → full answer.
- **Follow-up:** Users need to run `/plugin update workflow-skills` after merge so the cached copy picks up the new skill.

## CLAUDE.md updates
- **New skill:** `/rephrase` in the `workflow-skills` plugin. Manual-trigger only. When invoked, rephrase the user's latest message in native English, flag 2–3 vocab upgrades, then fully answer the underlying request in the same response — never stop at the rephrase block.
