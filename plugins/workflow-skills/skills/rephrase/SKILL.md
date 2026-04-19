---
name: rephrase
description: "Invoke ONLY when the user explicitly types /rephrase or asks Claude to rephrase/rewrite their message in native English. Restates the user's latest message in natural, native-English phrasing, highlights 2–3 vocabulary or grammar upgrades, AND THEN (in the same response) fully answers the original request. Do NOT auto-invoke. Do NOT stop after rephrasing."
---

# Rephrase

Help the user build native-English vocabulary and phrasing by showing how a fluent speaker would express the same idea — *and then* answer their question in the same response.

## When to run

Only when the user explicitly invokes this skill (e.g. types `/rephrase` or asks "rephrase what I said"). Never auto-trigger from ordinary messages, even if the phrasing sounds non-native.

## CRITICAL: One response, both halves

The rephrase is a **prelude**, not a substitute for the answer. A complete response to `/rephrase` always contains **both** the rephrase block **and** the full answer/action for the user's underlying request — in a single reply.

- Do **NOT** stop after the rephrase and wait for the user to re-ask.
- Do **NOT** treat the rephrase as a clarification step. The user's request is already clear — the rephrase is just a vocabulary lesson layered on top.
- After the `---` divider, continue exactly as you would have if the user had never typed `/rephrase`: run tools, write code, answer the question, whatever the request requires.

If you find yourself ending a `/rephrase` response at the divider, you are doing it wrong. Keep going.

## Process

1. **Rephrase** — Restate the user's most recent message in natural, native-English. Preserve the meaning exactly. Match the register: casual stays casual, technical stays technical. Keep it roughly the same length — don't inflate.

2. **Vocab upgrades** — Call out 2–3 specific improvements. For each, show:
   - the original fragment → the upgraded fragment
   - one short line on *why* (wrong word, awkward collocation, filler, redundancy, non-native word order, etc.)

3. **Answer** — Then, **in the same response**, do whatever the user asked: answer the question, run the tools, write the code, etc. Don't wait for re-confirmation.

## Output format

Use this exact structure:

> **You said:** "<direct quote of the user's latest message, verbatim>"
>
> **Native phrasing:** <the rephrased version>
>
> **Vocab upgrades:**
> - "<original>" → "<upgraded>" — <short reason>
> - "<original>" → "<upgraded>" — <short reason>
> - "<original>" → "<upgraded>" — <short reason>
>
> ---
>
> <normal answer to the actual request>

## Rules

- **No praise, no softening.** Skip "great question", "you're close", "nice try". The user wants the upgrade, not reassurance.
- **Silent filler cleanup is fine** — you don't need to flag every "um" / "uh" / "basically" unless the cleanup is the most useful lesson in that message.
- **Keep reasons one line.** Name the pattern (e.g. "non-standard collocation", "calque from another language", "filler", "tense mismatch"), then move on. Don't lecture.
- **If the message is already natural**, say so in one line and skip the vocab upgrades section — don't invent corrections to fill the template.
- **Scope:** rephrase only the user's *most recent* message. Do not retroactively rewrite earlier messages unless asked.
- **Do not translate** if the user wrote in another language — assume they wrote in English on purpose and want English upgrades.

## Example

> **You said:** "Can you help me figure out why my script is not working, I've been stuck on this for like forever."
>
> **Native phrasing:** Can you help me figure out why my script isn't working? I've been stuck on this for ages.
>
> **Vocab upgrades:**
> - "is not working" → "isn't working" — contraction reads more natural in casual speech
> - "for like forever" → "for ages" — "like forever" is conversational but "for ages" is the idiomatic native equivalent
> - comma splice → period + new sentence — two independent clauses shouldn't be joined with a comma
>
> ---
>
> Sure — paste the script and the error you're seeing and I'll take a look.
