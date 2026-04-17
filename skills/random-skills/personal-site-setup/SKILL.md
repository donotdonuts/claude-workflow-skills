---
name: personal-site-setup
description: Bootstrap a personal portfolio website from the donotdonuts.github.io template. Collects the user's name, photo, resume, social URLs, and visual-style preference (reference URL or written description), then generates the timeline / project cards / chatbot knowledge from the resume and applies a matching palette. Optional DeepSeek chatbot behind a Cloudflare Worker; the user names the bot and the agent proposes a matching emoji avatar. Deploys static to GitHub Pages. Use this when a user wants to build their own portfolio on this architecture.
---

# Personal site setup

Walk a new user through shipping their own portfolio at `https://<their-username>.github.io`. The architecture is fixed; the look, copy, and chatbot persona are all customised to the specific user.

## What they get

- **Single-page static site**, no bundler. GitHub Pages serves `main` at the repo root.
- **Hero** — their portrait + name + one-line location + one-line tagline.
- **Projects section** with a faded vertical timeline in the section head (wrench icons for work, book icons for education; each stop shows company, role, date, location) and a grid of project cards in the body. Both are generated from the user's resume.
- **Chatbot** (optional) — DeepSeek's OpenAI-compatible API behind a Cloudflare Worker that holds the API key. User picks the bot's name; agent proposes a matching emoji avatar. Bot replies render markdown. Two-layer rate limit.
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

3. **Timeline** — parse the resume into stops. One `<li class="tl-stop">` per role AND per degree. **Order present → earliest (top to bottom in DOM).** For each stop:
   ```html
   <li class="tl-stop tl-stop-work">   <!-- or tl-stop-edu -->
     <svg class="tl-icon tl-icon-work" aria-hidden="true">
       <use href="#icon-wrench"/>       <!-- or #icon-book -->
     </svg>
     <div class="tl-info">
       <strong>Company / School</strong>
       <span>Role / Degree</span>
       <em>Start — End</em>
       <i class="tl-loc">City, State</i>
     </div>
   </li>
   ```

4. **Projects** — six `<article class="project-card">` blocks, generated from notable projects/achievements in the resume. Each:
   ```html
   <article class="project-card">
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
   Use `<dd class="up">` / `<dd class="down">` to colour metrics.

5. **Chat greeting** (inside `<div class="chat-log">`) — rewrite using the chosen bot name + avatar emoji. Format:
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
- Lives inside the Projects `section-head`, just below the title, at `opacity: 0.45`. Hover bumps to 0.95.
- **DOM order = visual top-to-bottom order.** Present → earliest. NOT proportional to time — evenly distributed via flex `gap`.
- Icons defined once as `<symbol id="icon-*">` in the SVG sprite right after `<header>`. To add a new icon category:
  1. Add a `<symbol id="icon-foo">` with your SVG path
  2. Add `.tl-icon-foo { color: var(--ink-mute); }`
  3. Reference with `<svg class="tl-icon tl-icon-foo"><use href="#icon-foo"/></svg>`

### Chatbot flow
Client → Cloudflare Worker → DeepSeek's `chat/completions`. Worker holds the API key as a secret, enforces CORS (comma-separated `ALLOWED_ORIGIN`), sanitises + caps messages (≤20 msgs, ≤2000 chars), applies a per-IP sliding-window rate limit. Client has a 3-second cooldown. `SYSTEM_PROMPT` is the knowledge base.

## Gotchas

- **Bot bubble whitespace** — do NOT put `white-space: pre-wrap` on `.chat-bubble`. Bot replies render structured markdown HTML; pre-wrap preserves source indentation and creates huge blank gaps. Scope it to user bubbles only.
- **Axis-through-icon bug** — the timeline axis `<div>` must come BEFORE `<ol class="tl-stops">` in DOM order, AND markers need `z-index: 1`. Otherwise the line paints on top and bisects every icon.
- **Worker `package.json` type** — must be `"module"`, not `"commonjs"`.
- **CORS list format** — `ALLOWED_ORIGIN` in `wrangler.toml` is comma-separated. Include local dev origins so local preview can reach the live worker.
- **Repo name** — GitHub Pages user pages must be `<username>.github.io` exactly.
- **Scrollbar theming** — the `::-webkit-scrollbar` / Firefox `scrollbar-color` rules use `--border` / `--bg` tokens, so they auto-update when you apply a new palette.
- **Three bot-name places** — if you rename the bot, update all three: `js/chatbot.js` (`AVATAR` + `AVATAR_LABEL`), `index.html` (static greeting + `aria-label`), `worker/worker.js` (`SYSTEM_PROMPT`). Miss any and the bot will contradict itself.

## File map

```
index.html              Single-page site — all copy
css/styles.css          All styles; design tokens in :root
js/
  config.js             Runtime config (chatWorkerUrl)
  main.js               Footer year
  chatbot.js            Chat widget + markdown parser + cooldown; AVATAR / AVATAR_LABEL at top
assets/portrait.jpg     Committed web portrait (raw.jpg gitignored)
worker/
  worker.js             Cloudflare Worker — DeepSeek proxy, CORS, rate limit, SYSTEM_PROMPT
  wrangler.toml         Worker config (ALLOWED_ORIGIN, MODEL)
CLAUDE.md               Architecture notes for future sessions
```

## Pre-ship checklist

- [ ] All inputs gathered (username, name, tagline, location, resume, photo, socials, bot name + avatar, style preference)
- [ ] Visual palette approved and applied to `:root` + Google Fonts `<link>`
- [ ] `<title>` + meta description updated
- [ ] Hero name / location / tagline replaced
- [ ] Portrait placed at `assets/portrait.jpg` (colour-shifted to new `--bg` if needed)
- [ ] Every timeline stop generated from the user's resume — no template placeholders
- [ ] Project cards generated from the user's resume
- [ ] Connect section has the user's social URLs (unused rows deleted)
- [ ] Chat greeting uses the user's bot name + avatar
- [ ] `js/chatbot.js` `AVATAR` + `AVATAR_LABEL` match
- [ ] `worker/worker.js` `SYSTEM_PROMPT` = user's resume + chosen bot persona
- [ ] `worker/wrangler.toml` `ALLOWED_ORIGIN` includes the user's GitHub Pages URL
- [ ] `js/config.js` `chatWorkerUrl` set (or intentionally `""`)
- [ ] Local preview looks right, including mobile viewport
- [ ] `git push` → site live at `https://<username>.github.io/`
