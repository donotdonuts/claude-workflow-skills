---
name: personal-site-setup
description: Set up a personal portfolio website styled like donotdonuts.github.io — static HTML/CSS/JS with a cream IBM Plex Mono aesthetic, a faded vertical career timeline (wrench icons for work, book icons for education), and an optional DeepSeek chatbot behind a Cloudflare Worker. Deploys to GitHub Pages with no build step. Use when a user wants to bootstrap their own portfolio in this specific style.
---

# Personal site setup

Walk a new user through forking this template and shipping their own site at `https://<their-username>.github.io`.

## What they'll end up with

- **Single-page static site**, no bundler, no framework. GitHub Pages serves `main` at the repo root.
- **Stocktaper-inspired aesthetic** — cream `#fbf7eb` background, IBM Plex Mono on every element, `#9e9e9e` dividers, `#2f7d31`/`#c6392c` success/fail accents.
- **Hero** with a square portrait (works great with a WSJ-style hedcut), name, a one-line location, a one-line tagline.
- **Projects section** with a faded vertical timeline in the section head (wrench for work, book for education; each stop shows company, role, date, location) and a grid of project cards in the body.
- **Chatbot ("Pot 🫖" by default)** — optional. DeepSeek's OpenAI-compatible API behind a Cloudflare Worker that holds the API key. Bot replies render markdown. Two-layer rate limit (3s client cooldown + 10 req/60s per-IP worker cap).
- **Connect section** — email + LinkedIn + GitHub + Medium.

## Prerequisites

Check these before starting. If something's missing, stop and help the user install it.

| Needed for | Tool | Install |
|---|---|---|
| Everything | `git` | usually already installed |
| Everything | GitHub account + `gh` CLI | `brew install gh` then `gh auth login` |
| Everything | `python3` (local preview only) | usually already installed |
| Chatbot | Cloudflare account (free tier is fine) | https://dash.cloudflare.com |
| Chatbot | `wrangler` CLI | `npm install -g wrangler` then `wrangler login` |
| Chatbot | DeepSeek API key | https://platform.deepseek.com/ → API keys |
| Portrait color-shift | Node.js (any recent version) | `brew install node` |

## Step-by-step

### 1. Create the GitHub repo

GitHub Pages user sites MUST be at `<username>.github.io`. If the user's handle is `jane`, the repo is `jane/jane.github.io`.

```bash
gh repo create <username>.github.io --public --description "Personal website"
```

### 2. Fork / clone the template

Either click "Use this template" on https://github.com/donotdonuts/donotdonuts.github.io, or:

```bash
git clone https://github.com/donotdonuts/donotdonuts.github.io my-site
cd my-site
rm -rf .git
git init -b main
git remote add origin https://github.com/<username>/<username>.github.io.git
```

### 3. Replace the content in `index.html`

Open `index.html`. Every section is commented. Work top to bottom:

1. **`<head>`** — update `<title>` and `<meta name="description">`.
2. **Hero** (around the first `<section class="hero">`):
   - `<h1 class="hero-title">` → your name
   - `<p class="hero-location">` → a single phrase like `NYC metropolitan` (rendered uppercase in `--ink-mute`)
   - `<p class="hero-tagline">` → one sentence about who you are
3. **Timeline** (inside `<aside class="timeline-rail">`): replace the seven `<li class="tl-stop">` blocks. **Order top-to-bottom = present → earliest.** Each stop has:
   - `<svg class="tl-icon tl-icon-work"><use href="#icon-wrench"/></svg>` for work, or `tl-icon-edu` + `#icon-book` for education
   - `<strong>` — company or school
   - `<span>` — role or degree
   - `<em>` — date or date range
   - `<i class="tl-loc">` — location (`"New York, NY"`, `"Remote"`, etc.)
4. **Projects** (inside `.project-grid`): six `<article class="project-card">` blocks. Each has:
   - `<span class="project-tag">` — category (`Optimization`, `NLP`, etc.)
   - `<h3>` — project name
   - `<p>` — 1–2 sentence summary
   - `<dl class="project-metrics">` — up to two metric pairs. Use `<dd class="up">` for green positives, `<dd class="down">` for red negatives.
   - `<ul class="tag-list small">` — stack
5. **Chat greeting** (inside `<div class="chat-log">`) — update to match the new name if you rename "Pot".
6. **Connect** (inside `.connect-list`) — email, LinkedIn, GitHub, Medium. Unused rows can be deleted.

### 4. Replace the portrait

A square portrait looks best. WSJ-style hedcut works beautifully, but any cream-toned square photo is fine.

```bash
# Drop your source image at the repo root
cp /wherever/my-portrait.jpg raw.jpg

# Resize to 720px and save to assets/
sips -Z 720 raw.jpg --out assets/portrait.jpg
```

If the photo's paper color doesn't match `#fbf7eb`, use the included script to shift it:

```bash
cd /tmp && rm -rf img-fix && mkdir img-fix && cd img-fix
npm init -y > /dev/null
npm install jimp@0.22 --silent
node /path/to/my-site/.claude/skills/personal-site-setup/scripts/shift-portrait.js \
  /path/to/my-site/raw.jpg \
  /path/to/my-site/assets/portrait.jpg
```

The script samples the four corners, computes a delta from their average to `#fbf7eb`, and adds it to every pixel. Halftone texture is preserved.

`raw.jpg` is gitignored by default — only the resized `assets/portrait.jpg` ships.

### 5. Deploy the Cloudflare Worker (skip if you don't want the chatbot)

From the repo:

```bash
cd worker
wrangler login
wrangler secret put DEEPSEEK_API_KEY     # paste the DeepSeek API key
```

Edit `worker/wrangler.toml`:
```toml
ALLOWED_ORIGIN = "https://<username>.github.io,http://localhost:8000,http://127.0.0.1:8000"
MODEL          = "deepseek-chat"          # or "deepseek-reasoner"
```

Edit `worker/worker.js` → `SYSTEM_PROMPT`. This string IS the chatbot's knowledge base — replace Leon's resume with yours, keeping the same structure (About / Current role / Past roles / Education / Tool box). The default persona is "Pot 🫖" — change the first sentence if you want a different name or avatar.

Deploy:
```bash
wrangler deploy
```
Wrangler prints the Worker URL. Copy it.

### 6. Wire the chat URL

Edit `js/config.js`:
```js
window.SITE_CONFIG = {
  chatWorkerUrl: "https://<worker-name>.<account>.workers.dev",
};
```

If skipping the chatbot, leave it `""` — the chat input will show a friendly disabled state.

If you renamed the bot, also update in `js/chatbot.js`:
- `AVATAR` — emoji shown in the avatar chip (default `🫖`)
- `AVATAR_LABEL` — accessible name (default `"Pot"`)

### 7. Preview + push

```bash
python3 -m http.server 8000       # preview at http://localhost:8000
```

Open it, click through every section, test the chat. Then:

```bash
git add .
git commit -m "initial: personal site"
git push -u origin main           # first push; --force only needed if the repo already has placeholder commits
```

GitHub Pages builds automatically. The site is live at `https://<username>.github.io/` within ~60 seconds. Check the **Actions** tab if it doesn't appear.

## Reskinning / customizing

### Design tokens — `css/styles.css` `:root`
Every color lives as a CSS custom property. To reskin, change these values in one place:
- `--bg` — page background (currently cream `#fbf7eb`)
- `--ink` — primary text (currently `#141414`)
- `--ink-soft` / `--ink-mute` / `--ink-faint` — decreasing text hierarchy
- `--border` / `--border-strong` — dividers and marker strokes
- `--up` / `--down` — positive/negative metric colors
- `--accent-ink` — link color

### Font
Swap the `<link href="...google fonts...">` in `<head>` and update `--font-mono` in `:root`. The site uses the same font for body, headings, buttons — if you mix families, the mono-terminal aesthetic breaks.

### Section layout
Every section uses `.section-grid: 280px 1fr`. The 280px column fits the longest role label ("Senior Planner / Data Scientist") without wrapping. If your labels are shorter, tighten to 240px; longer, widen to 320px.

### Timeline icons
Defined once as `<symbol id="icon-*">` in the SVG sprite right after `<header>` in `index.html`. To add a new category (e.g., volunteering):
1. Add a new `<symbol id="icon-heart">` with your SVG path
2. Add `.tl-icon-volunteer { color: var(--ink-mute); }` in `css/styles.css`
3. Reference it with `<svg class="tl-icon tl-icon-volunteer"><use href="#icon-heart"/></svg>`

### Chatbot knowledge
Edit `SYSTEM_PROMPT` at the top of `worker/worker.js`, then `cd worker && wrangler deploy`. Live on the next message — no cache to flush.

### Rate-limit thresholds
- Worker: `RATE_LIMIT_MAX` + `RATE_LIMIT_WINDOW_MS` at the top of `worker/worker.js`
- Client: `COOLDOWN_MS` at the top of `js/chatbot.js`

## Gotchas learned the hard way

- **Scrollbars** — default OS scrollbars look jarring on cream. The `::-webkit-scrollbar` + Firefox `scrollbar-color` rules in `styles.css` keep them in-theme. If you add a new scrollable region, make sure its track matches the element's background.
- **Bot bubble whitespace** — do **not** put `white-space: pre-wrap` on `.chat-bubble`. Bot replies render structured markdown HTML; pre-wrap preserves the source indentation and creates huge blank gaps between paragraphs. Pre-wrap is scoped to user bubbles only (`.chat-msg-user .chat-bubble`).
- **Axis-through-dot bug** — the timeline axis `<div>` must come BEFORE the stops in DOM order, AND markers need `z-index: 1`. Otherwise the line paints on top and bisects every icon.
- **Worker `package.json` type** — must be `"module"`. Wrangler is lenient but `node --check` isn't.
- **CORS list** — `ALLOWED_ORIGIN` in `wrangler.toml` is comma-separated. Include local dev origins (`http://localhost:8000`, `http://127.0.0.1:8000`) so your local preview can call the live worker.
- **Repo name** — GitHub Pages user pages must be named `<username>.github.io` exactly. Project pages (e.g., `my-portfolio`) serve at `/my-portfolio/` and need relative paths — the template uses absolute paths, so stick with a user page.
- **Timeline positions are NOT proportional to time** — they're evenly spaced via flex `gap`. Don't waste effort calculating months-since-epoch.
- **280px column** — the `.section-grid` left column is calibrated to the longest role label. Shrinking it wraps `Senior Planner / Data Scientist` mid-name; widening it makes the hero feel lopsided.

## File map (what you're editing)

```
index.html              Single-page site — all copy lives here
css/styles.css          All styles; design tokens in :root
js/
  config.js             Runtime config (chatWorkerUrl — one line)
  main.js               Footer year only
  chatbot.js            Chat UI + markdown parser + cooldown
assets/portrait.jpg     Committed web portrait (raw.jpg gitignored)
worker/
  worker.js             Cloudflare Worker — DeepSeek proxy + CORS + rate limit
  wrangler.toml         Worker config (ALLOWED_ORIGIN, MODEL)
  README.md             Worker-specific deploy notes
CLAUDE.md               Architecture notes for future Claude sessions
```

## Checklist before shipping

- [ ] `<title>` + meta description updated
- [ ] Name, location, tagline in hero match you
- [ ] Portrait replaced at `assets/portrait.jpg`
- [ ] All timeline stops replaced (no "Mars Snacking" / "Chinatex" placeholders)
- [ ] All project cards replaced (no Leon's projects lingering)
- [ ] Social URLs in Connect replaced (or deleted rows)
- [ ] Chat greeting matches the bot name if renamed
- [ ] `worker/worker.js` `SYSTEM_PROMPT` replaced with your resume
- [ ] `worker/wrangler.toml` `ALLOWED_ORIGIN` includes your GitHub Pages URL
- [ ] `js/config.js` `chatWorkerUrl` set (or intentionally empty)
- [ ] Local preview looks right in both light mode and mobile viewport
- [ ] `git push` → site live at `https://<username>.github.io/`
