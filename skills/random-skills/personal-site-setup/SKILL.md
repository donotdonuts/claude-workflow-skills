---
name: personal-site-setup
description: Bootstrap a personal portfolio website from the donotdonuts.github.io template. Collects the user's name, photo, resume, social URLs, and visual-style preference (reference URL or written description), then generates the timeline / project cards / chatbot knowledge from the resume and applies a matching palette. Optional DeepSeek chatbot behind a Cloudflare Worker; the user names the bot and the agent proposes a matching emoji avatar. Deploys static to GitHub Pages. Use this when a user wants to build their own portfolio on this architecture.
---

# Personal site setup

Walk a new user through shipping their own portfolio at `https://<their-username>.github.io`. The architecture is fixed; the look, copy, and chatbot persona are all customised to the specific user.

## What they get

- **Single-page static site**, no bundler. GitHub Pages serves `main` at the repo root.
- **Hero** — their portrait + name + one-line location + one-line tagline.
- **Projects section** with a faded vertical timeline in the section head (wrench icons for work, book icons for education, sparkle icons for vibe / side-project stops; each stop shows company, role, date, location) and a grid of project cards in the body — both generated from the user's resume.
- **Timeline ↔ cards filter** — hover or keyboard-focus a timeline stop to hide unrelated project cards; click to pin the filter (click again to clear). Only stops that have ≥1 tied card become interactive; others stay inert.
- **Folded cards** — each project card shows only its category + title + tool tags by default; the summary paragraph and metric row appear on hover / focus, keeping the grid scannable.
- **Chatbot** (optional) — a floating bottom-right launcher + pop-out panel (not an inline page section) backed by DeepSeek's OpenAI-compatible API behind a Cloudflare Worker that holds the API key. User picks the bot's name; agent proposes a matching emoji avatar. Bot replies render markdown. Two-layer rate limit.
- **Connect section** — email + the user's social URLs.

## Prerequisites

| Needed for | Tool | Install |
|---|---|---|
| Everything | `git` | usually already installed |
| Everything | GitHub account + `gh` CLI | `brew install gh` then `gh auth login` |
| Everything | `python3` (local preview) | usually already installed |
| Chatbot | Cloudflare account (free tier) | https://dash.cloudflare.com |
| Chatbot | `wrangler` CLI | `npm install -g wrangler` then `wrangler login` |
| Chatbot | DeepSeek API key | https://platform.deepseek.com/ → API keys |
| Portrait shift | Node.js | `brew install node` |

## Step-by-step

### 1. Gather inputs from the user

**Do this before touching any files.** Collect everything at once so later steps are automated edits. Mix `AskUserQuestion` for multiple-choice and direct prompts for free-text.

Pull each of these from the user:

| Input | How to ask | Example |
|---|---|---|
| GitHub username | direct | `jane` (the repo will be `jane.github.io`) |
| Display name | direct | `Jane Doe` or `Jane "JD" Doe` |
| Location phrase | direct, short | `NYC metropolitan`, `Remote`, `Tokyo` |
| Tagline | direct, one sentence | `I build ML systems and love shipping.` |
| Resume | paste text or path to a file | full resume — used to populate timeline, project cards, chatbot knowledge |
| Photo | path to a square image on disk | `/Users/jane/Desktop/headshot.jpg`. User can drop it at repo root as `raw.jpg` after cloning. |
| Social URLs | direct, each optional | LinkedIn / GitHub profile / Medium / personal email |
| Chatbot? | `AskUserQuestion` | yes / no |
| Chatbot name (if yes) | direct | `Pot`, `Nova`, `Echo`, etc. |
| Visual style | `AskUserQuestion` | "Paste a URL I like" OR "Describe it in words" |

**After collecting the chatbot name**, propose 2–3 emoji avatars that thematically match and let the user pick. Examples:

| Name | Proposed avatars |
|---|---|
| Pot | 🫖 (teapot) · 🍲 · 🎨 |
| Nova | 🌟 · 💫 · 🌠 |
| Echo | 📣 · 🔊 · 🌀 |
| Ember | 🔥 · 🪵 · ✨ |
| Atlas | 🗺️ · 🧭 · 🌍 |
| Bit | 💾 · 🔢 · 🤖 |
| Sage | 🌿 · 📖 · 🦉 |

If nothing obvious fits, offer neutrals: 🤖, 💬, 🪄. Store the chosen emoji + name — you'll write them into the code later.

### 2. Create the GitHub repo

```bash
gh repo create <username>.github.io --public --description "Personal website"
```

GitHub Pages user sites MUST be at `<username>.github.io`.

### 3. Clone the template

```bash
git clone https://github.com/donotdonuts/donotdonuts.github.io my-site
cd my-site
rm -rf .git
git init -b main
git remote add origin https://github.com/<username>/<username>.github.io.git
```

### 4. Pick a visual style

The template defaults to a cream + IBM Plex Mono aesthetic. Overwrite it based on the user's answer from Step 1.

#### 4a. If the user gave a URL

Pull the page's CSS and extract tokens:

```bash
curl -sL "<url>" -o /tmp/ref.html
grep -oE 'href="[^"]+\.css[^"]*"' /tmp/ref.html | sort -u
curl -sL "<origin>/<css-path>" -o /tmp/ref-1.css

# font actually applied to body
grep -oE 'body[^{]{0,30}\{[^}]+\}' /tmp/ref-1.css | head -5
# all CSS custom-property definitions
grep -oE -- '--[a-zA-Z-]+:[^;}]+' /tmp/ref-1.css | sort -u | head -60
```

Look for: background hex, foreground/ink hex, border hex, accent hex, font-family applied to body, `@font-face` URLs.

#### 4b. If the user gave a description

Translate the description into concrete tokens. Heuristics:

| Words | Implication |
|---|---|
| "minimal", "editorial", "paper" | Cream / off-white bg, dark ink, thin dividers |
| "dark", "terminal", "IDE" | Near-black bg (`#0f1115`), light ink, subtle grey borders |
| "warm", "analog" | Slightly yellow cream (`#faf5e8`), brown-black ink |
| "brutalist" | Pure white or pure black, 2px+ solid borders |
| "techy", "data" | Monospace (IBM Plex Mono, JetBrains Mono), cool greys |
| "magazine", "editorial" | Serif (EB Garamond, Fraunces), generous leading |
| "playful" | One saturated accent, otherwise muted |

#### 4c. Propose + apply

Compile 13 tokens + a font stack. **Show the proposed palette as a code block and get approval before editing files.**

```css
:root {
  --bg:             <hex>;   /* page background */
  --bg-soft:        <hex>;   /* sub-panels — usually --bg mixed ~3% toward --ink */
  --bg-hover:       <hex>;   /* tag/chip hover */
  --card-bg:        <hex>;   /* opaque card fill (white if light theme) */
  --ink:            <hex>;   /* primary text */
  --ink-soft:       <hex>;   /* ~80% of --ink */
  --ink-mute:       <hex>;   /* ~60% */
  --ink-faint:      <hex>;   /* ~40% */
  --border:         <hex>;   /* subtle dividers */
  --border-strong:  <hex>;   /* load-bearing dividers */
  --up:             <hex>;   /* positive metrics (green-ish by default) */
  --down:           <hex>;   /* negative metrics (red-ish by default) */
  --accent-ink:     <hex>;   /* links */
  --font-mono:      "<Family>", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
}
```

Then:
1. Open `css/styles.css`, find the `:root` block, replace values.
2. Open `index.html`, update the Google Fonts `<link>` in `<head>` with the new font family + weights.

### 5. Generate content from resume + inputs

Use the resume + other inputs from Step 1 to populate `index.html`:

1. **`<head>`** — `<title>` = `<Display Name> — <first-role-from-resume>`; `<meta name="description">` from tagline.

2. **Hero**:
   - `<h1 class="hero-title">` ← display name
   - `<p class="hero-location">` ← location phrase
   - `<p class="hero-tagline">` ← tagline

3. **Timeline** — parse the resume into stops. One `<li class="tl-stop">` per role, per degree, AND per ongoing personal side-project category the user wants to surface. **Order present → earliest (top to bottom in DOM).** Pick a short `data-experience` slug for each (e.g. `mars`, `vibe`, `coach`, `gatech`) — it's what the filter uses to tie stops to cards. Add `tabindex="0"` only on stops that have ≥1 tied project card (others stay inert).

   ```html
   <li class="tl-stop tl-stop-work" data-experience="<slug>" tabindex="0">
     <!-- tl-stop-work | tl-stop-edu | tl-stop-vibe   (pick one) -->
     <svg class="tl-icon tl-icon-work" aria-hidden="true">
       <use href="#icon-wrench"/>       <!-- #icon-wrench | #icon-book | #icon-sparkle -->
     </svg>
     <div class="tl-info">
       <strong>Company / School</strong>
       <span>Role / Degree</span>
       <em>Start — End</em>
       <i class="tl-loc">City, State</i>
     </div>
   </li>
   ```

   Drop `tabindex="0"` on education / old-role stops that don't have project cards tied to them — `js/main.js` auto-detects those at load and leaves them non-interactive.

4. **Projects** — ~six `<article class="project-card">` blocks, generated from notable projects/achievements in the resume. Each card MUST carry a `data-experience` slug matching the stop it came from, or it won't participate in the filter:

   ```html
   <article class="project-card" data-experience="<slug>">
     <header class="project-head">
       <span class="project-tag">Category</span>
       <h3>Project Title</h3>
     </header>
     <p>1–2 sentence summary drawn from the resume bullet.</p>
     <dl class="project-metrics">
       <div><dt>Metric</dt><dd class="up">+value</dd></div>
       <div><dt>Metric</dt><dd>value</dd></div>
     </dl>
     <ul class="tag-list small"><li>Tool</li><li>Tool</li></ul>
   </article>
   ```

   Use `<dd class="up">` / `<dd class="down">` to colour metrics. Cards render **folded** by default — only the tag, title, and tool tags are visible until hover / focus-within reveals the summary + metrics. Keep summaries tight; they only exist to reward a hover.

5. **Chat greeting** — the bot's opening message is inline HTML inside `#chat-panel` in `index.html` (inside the panel's `<div class="chat-log">`), so it renders instantly when the user first opens the pop-out. Rewrite it using the chosen bot name + avatar emoji. Format:
   ```html
   <div class="chat-msg chat-msg-bot">
     <span class="chat-avatar" aria-label="<Bot Name>">EMOJI</span>
     <div class="chat-bubble">
       <p>Hi, I'm <strong><Bot Name></strong> — <Display Name>'s AI assistant, <verb'd> from <his/her> resume.</p>
       <p>Ask me about:</p>
       <ul>
         <li>Companies / roles</li>
         <li>Methods / approaches</li>
         <li>Projects / skills / education</li>
       </ul>
       <p>What would you like to know?</p>
     </div>
   </div>
   ```

6. **Connect** — email + each supplied social URL as a `<li>` in `.connect-list`. Delete rows for any platform not provided.

### 6. Add the portrait

Ask where their photo is. Copy it to the repo root as `raw.jpg`, then resize:

```bash
cp <user-photo-path> raw.jpg
mkdir -p assets
sips -Z 720 raw.jpg --out assets/portrait.jpg
```

If the photo's background doesn't match the new `--bg`, shift it with the bundled script:

```bash
cd /tmp && rm -rf img-fix && mkdir img-fix && cd img-fix
npm init -y > /dev/null
npm install jimp@0.22 --silent
node <this-skill-dir>/scripts/shift-portrait.js \
  /path/to/my-site/raw.jpg \
  /path/to/my-site/assets/portrait.jpg \
  "#<your-bg-hex>"
```

Defaults to `#fbf7eb` if the third arg is omitted. `raw.jpg` is gitignored.

### 7. Configure the chatbot (skip if user said no)

#### 7a. Worker

```bash
cd worker
wrangler login
wrangler secret put DEEPSEEK_API_KEY
```

`worker/wrangler.toml`:
```toml
ALLOWED_ORIGIN = "https://<username>.github.io,http://localhost:8000,http://127.0.0.1:8000"
MODEL          = "deepseek-chat"
```

`worker/worker.js` → `SYSTEM_PROMPT` — rewrite from the user's resume. Keep the section structure (About / Current role / Past roles / Education / Tool box). Also rewrite the opening persona sentence using the bot's name + avatar:

```js
const SYSTEM_PROMPT = `You are "<Bot Name>" <EMOJI> — a friendly, concise AI assistant embedded on <Display Name>'s personal website. …`;
```

Deploy:
```bash
wrangler deploy
```

#### 7b. Client

`js/config.js`:
```js
window.SITE_CONFIG = {
  chatWorkerUrl: "https://<worker>.workers.dev",
};
```

`js/chatbot.js` — update the constants at the top:
```js
const AVATAR = "<EMOJI>";
const AVATAR_LABEL = "<Bot Name>";
```

### 8. Preview + push

```bash
python3 -m http.server 8000       # http://localhost:8000
```

Click through every section. Test the chat. Resize to mobile width. Then:

```bash
git add .
git commit -m "initial: personal site"
git push -u origin main
```

Live at `https://<username>.github.io/` within ~60 seconds.

## Template architecture (don't change)

### Section layout
Every section uses `.section-grid: 280px 1fr`. The 280px column fits the longest timeline label. Tighten to 240px if all labels are short, widen to 320px if long.

### Timeline
- Lives inside the Projects `section-head`, just below the title, at `opacity: 0.45`. Hover, focus, or an active filter bumps it to 0.95.
- **DOM order = visual top-to-bottom order.** Present → earliest. NOT proportional to time — evenly distributed via flex `gap`.
- Three icon kinds out of the box: `#icon-wrench` (work, `.tl-stop-work`), `#icon-book` (education, `.tl-stop-edu`), `#icon-sparkle` (vibe / side-project, `.tl-stop-vibe`). All three `<symbol>` definitions live in the SVG sprite right after `<header>`. To add a new icon category:
  1. Add a `<symbol id="icon-foo">` with your SVG path
  2. Add `.tl-icon-foo { color: var(--ink-mute); }`
  3. Reference with `<svg class="tl-icon tl-icon-foo"><use href="#icon-foo"/></svg>`
- Every stop carries `data-experience="<slug>"`; stops whose slug matches at least one project card also get `tabindex="0"` so `js/main.js` can make them filter-interactive.

### Project filter (click + hover)
Driven entirely by `js/main.js`, zero config — it scans the DOM on load and wires handlers only where they apply.

- On load, every stop whose `data-experience` slug is present on at least one `.project-card` gets `.tl-stop-has-projects` + `role="button"` + `aria-pressed="false"`. Stops without tied cards stay inert.
- **Hover / focus** an interactive stop → temp-filter: non-matching cards become `.is-dim` (the grid adds `.is-filtering`, which CSS translates into `display: none` on dimmed cards — they're removed from layout, not just faded).
- **Click** (or `Enter` / `Space`) → lock: stop gets `.is-locked`, full opacity, ink-coloured icon, underlined company name. Click the same stop again to clear; click another to switch.
- While locked, hovering a different stop previews its cards; `mouseleave` on the rail (or `focusout` out of it) snaps back via `restoreLockedView()`.
- **Wiring a new experience is purely markup:** add `data-experience="<slug>"` to both the stop and every tied card, plus `tabindex="0"` on the stop. No JS changes.

### Folded project cards
Each card renders collapsed: `project-tag` + `h3` + `.tag-list.small` only. The summary `<p>` and `.project-metrics` row appear on `:hover` / `:focus-within`. Pure CSS — `.project-card > p { display: none }` flips to `display: block`; `.project-metrics` flips to `display: flex`. `.project-grid` uses `align-items: start` so an expanded card doesn't force its row neighbours taller. The fold state composes cleanly with the filter — `.is-dim` cards are `display: none`, so they never expand.

### Chatbot UI: floating launcher + panel
The chatbot is **not** an inline page section — it's a floating widget that overlays every page. Three siblings live after `<footer>` in `index.html`:
- `#chat-launcher` — fixed bottom-right circular button (56 px, ink background) with the avatar emoji + a soft pulse ring. Always visible.
- `#chat-panel` — fixed pop-out panel above the launcher, starts with the `hidden` attribute. Contains the panel header (avatar + bot name + subtitle + `×` close) and the existing `#chat-widget` (log, form, hint, suggestion chips). The initial bot greeting is inline HTML inside this panel so it ships instantly on page load.
- `#chat-nudge` — a pill floating just left of the launcher with a triangular tail pointing at it (`pointer-events: none` so it never blocks the click). Dismisses the first time the panel opens; CSS hides it entirely below 480 px.

Open / close is wired in `js/chatbot.js`: click `#chat-launcher` toggles; click `#chat-close` or press `Escape` closes. `openPanel()` manages `hidden`, `aria-expanded`, focus, and scroll-to-bottom; `closePanel()` restores focus to the launcher. The site `<nav>` only links Home / Projects / Connect — no "Ask" entry, since the launcher is always reachable.

### Chatbot flow
Client → Cloudflare Worker → DeepSeek's `chat/completions`. Worker holds the API key as a secret, enforces CORS (comma-separated `ALLOWED_ORIGIN`), sanitises + caps messages (≤20 msgs, ≤2000 chars), applies a per-IP sliding-window rate limit. Client has a 3-second cooldown. `SYSTEM_PROMPT` is the knowledge base.

## Gotchas

- **Bot bubble whitespace** — do NOT put `white-space: pre-wrap` on `.chat-bubble`. Bot replies render structured markdown HTML; pre-wrap preserves source indentation and creates huge blank gaps. Scope it to user bubbles only.
- **Axis-through-icon bug** — the timeline axis `<div>` must come BEFORE `<ol class="tl-stops">` in DOM order, AND markers need `z-index: 1`. Otherwise the line paints on top and bisects every icon.
- **`data-experience` slug drift** — the slug on a `.tl-stop` must match the slug on every card it should filter to, character-for-character. A typo on either side silently makes the stop inert (no cards → no `.tl-stop-has-projects` → no handlers) or orphans cards so they never reappear under any filter. Pick slugs in Step 5 and reuse them verbatim.
- **`tabindex="0"` only where it matters** — only add `tabindex="0"` to stops that have ≥1 tied card. Adding it to purely-informational stops (old roles, degrees with no project) makes them tab-focusable and advertises interactivity the JS never wires up.
- **Folded-card summaries are load-bearing short** — since the summary only appears on hover / focus, treat it as a reward, not the main copy. Put the important info in the title + metrics, which are always visible.
- **Worker `package.json` type** — must be `"module"`, not `"commonjs"`.
- **CORS list format** — `ALLOWED_ORIGIN` in `wrangler.toml` is comma-separated. Include local dev origins so local preview can reach the live worker.
- **Repo name** — GitHub Pages user pages must be `<username>.github.io` exactly.
- **Scrollbar theming** — the `::-webkit-scrollbar` / Firefox `scrollbar-color` rules use `--border` / `--bg` tokens, so they auto-update when you apply a new palette.
- **Four bot-name places** — if you rename the bot, update all four: `js/chatbot.js` (`AVATAR` + `AVATAR_LABEL`), `index.html` static greeting + `#chat-launcher` / `#chat-panel` header (avatar emoji, aria-labels, title, subtitle, nudge copy), and `worker/worker.js` (`SYSTEM_PROMPT`). Miss any and the bot will contradict itself.

## File map

```
index.html              Single-page site — all copy, plus the floating
                        #chat-launcher / #chat-panel / #chat-nudge siblings
                        after <footer>, and the SVG sprite with
                        #icon-wrench / #icon-book / #icon-sparkle after <header>
css/styles.css          All styles; design tokens in :root; .is-filtering /
                        .is-dim / .is-locked rules drive the timeline filter;
                        folded-card display rules on .project-card > p and
                        .project-metrics
js/
  config.js             Runtime config (chatWorkerUrl)
  main.js               Footer year + timeline↔cards filter (hover / click
                        / Enter / Space). Auto-wires any stop whose
                        data-experience matches ≥1 card
  chatbot.js            Launcher open/close, chat widget, markdown parser,
                        cooldown; AVATAR / AVATAR_LABEL at top
assets/portrait.jpg     Committed web portrait (raw.jpg gitignored)
worker/
  worker.js             Cloudflare Worker — DeepSeek proxy, CORS, rate limit,
                        SYSTEM_PROMPT
  wrangler.toml         Worker config (ALLOWED_ORIGIN, MODEL)
CLAUDE.md               Architecture notes for future sessions
```

## Pre-ship checklist

- [ ] All inputs gathered (username, name, tagline, location, resume, photo, socials, bot name + avatar, style preference)
- [ ] Visual palette approved and applied to `:root` + Google Fonts `<link>`
- [ ] `<title>` + meta description updated
- [ ] Hero name / location / tagline replaced
- [ ] Portrait placed at `assets/portrait.jpg` (colour-shifted to new `--bg` if needed)
- [ ] Every timeline stop generated from the user's resume — no template placeholders — with correct icon type (wrench / book / sparkle) and `data-experience` slug
- [ ] `tabindex="0"` present on every stop that has ≥1 tied project card, absent elsewhere
- [ ] Project cards generated from the user's resume, each with `data-experience` matching its stop
- [ ] Hover + click + `Enter` / `Space` on an interactive stop filters the project grid correctly in local preview
- [ ] Folded-card summaries are tight (they only appear on hover)
- [ ] Connect section has the user's social URLs (unused rows deleted)
- [ ] Chat greeting uses the user's bot name + avatar; floating launcher + panel + nudge all show the right emoji and copy
- [ ] `js/chatbot.js` `AVATAR` + `AVATAR_LABEL` match
- [ ] `worker/worker.js` `SYSTEM_PROMPT` = user's resume + chosen bot persona
- [ ] `worker/wrangler.toml` `ALLOWED_ORIGIN` includes the user's GitHub Pages URL
- [ ] `js/config.js` `chatWorkerUrl` set (or intentionally `""`)
- [ ] Local preview looks right, including mobile viewport
- [ ] `git push` → site live at `https://<username>.github.io/`
