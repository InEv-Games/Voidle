# itch.io Web Demo — 1-day plan

Goal: a browser-only demo on itch.io that runs from the main menu to the
Civilization 0 ending (rocket from the Moon reaches a new world), with no
saving, and ends by sending players to the Steam page and/or collecting their
email into a Google Sheet.

Cut point: **unchanged** — the demo ends when the Advanced Planetary Rocket
reaches its target (Civilization 0 complete). Too long → fix with balance, not
by moving the cut.

## Progress (2026-10-23)

| Block | State |
|-------|-------|
| 1 Web export | Code done: Web preset (`demo` feature, no threads), web renderer = Compatibility, roads build on the main thread on web. **Not built / not tested in a browser.** |
| 2 Demo mode | Done: no save / load / autosave, menu shows PLAY DEMO + SETTINGS only, pause menu without SAVE / QUIT, console off. |
| 3 Intro | Goal card after NEW GAME / PLAY DEMO. Tutorial run-through still open. |
| 4 End screen | Done: stats line, WISHLIST ON STEAM, email form → Apps Script. Waits for the two URLs in `res://resources/demo/demo_config.tres` (Inspector). |
| 5 Sheet | User. |
| 6 Moon moment | Done: "FIRST STEP ON THE MOON" banner, once per world. |
| UI scenes | Intro card, end screen, signup block and Moon banner are scenes in `scenes/ui/` — texts, colours, fonts and layout edited in the Godot editor. |
| 7–8 | User. |

Known risk — WebGL 2 uniform limit: the territory include
(`district_territory.gdshaderinc`) uses ~15 KB of the guaranteed 16 KB uniform
buffer (128 districts × pos / col / sea + 512 spokes). If the planet shader
fails to compile in a browser, lower `MAX_DISTRICTS` to 64 in the include and
`MAX_TERRITORIES` in PlanetaryView together.

## Blocks

| # | Block | Time | Who |
|---|-------|------|-----|
| 1 | Web export works | 2 h | Claude + test by user |
| 2 | Demo build mode (no saves) | 1 h | Claude |
| 3 | Intro + menu polish | 1 h | Claude |
| 4 | End screen: Steam + email | 1.5 h | Claude |
| 5 | Google Sheet backend | 0.5 h | User (script below) |
| 6 | First-Moon-city moment | 0.5 h | Claude |
| 7 | Browser playtest, start → end | 2 h | User, fixes by Claude |
| 8 | itch.io upload | 0.5 h | User |

### 1. Web export works (morning, first — biggest risk)
- Add a **Web** export preset (export path `Builds/Web/index.html`), custom
  feature tag `demo`.
- Renderer: project is Forward+, which the web can't run. Set
  `rendering/renderer/rendering_method.web = "gl_compatibility"` so desktop
  stays Forward+ and web uses WebGL 2.
- Threads: export **without thread support** (no SharedArrayBuffer setup on
  itch). `RoadNetwork.gd` must fall back to building roads on the main thread
  when `OS.has_feature("web")`.
- Check every shader in the browser (planet, moon, gas, territory, terrain
  map, star). Watch for WebGL 2 differences: integer/loop limits, texture
  formats (river RG8, wind texture), `textureSize`.
- Check performance on an average laptop: planet view, Local System view,
  Skill Tree, many freighters.
- Done when: a new game runs in Chrome and Firefox without errors in the
  browser console, at a smooth frame rate.

### 2. Demo build mode — no saves
- `GameState.DEMO_BUILD := OS.has_feature("demo") or OS.has_feature("web")`.
- In demo: no autosave, no `save()` writes, no load, no offline progress /
  welcome-back screen. A refresh starts over (say so on the itch page).
- Main menu in demo: hide **Continue**, **Showcase** and **Quit**; version
  label "Demo v0.x".
- DevConsole off in the demo build.

### 3. Intro + menu polish
- One short intro card after NEW GAME: 2–3 lines — who you are, the goal
  ("Reach orbit, settle the Moon, launch for a new world"), "about an hour".
- Run the tutorial from the first click to the first quest once; fix anything
  that blocks.

### 4. End screen — Steam + email
On the existing "CIVILIZATION 0 COMPLETE" screen (HUDManager `_show_act1_complete`):
- Short stats: time played, cities founded, research bought.
- **Wishlist on Steam** button → `OS.shell_open(STEAM_URL)` (opens a new tab;
  fine because it comes from a click).
- **Email form**: one field + "Send me news about Voidle" + a consent line
  ("We'll only use this to tell you about Voidle. Unsubscribe any time.") +
  SEND. Basic format check; success / error message; never blocks the screen.
- Sends `POST` (`Content-Type: text/plain`, JSON body) with HTTPRequest to the
  Google Apps Script URL. `text/plain` avoids the browser's CORS preflight; the
  row is written even if the browser can't read the reply, so treat "request
  sent" as success.
- KEEP PLAYING stays; the sandbox must not break after the end (Civ 1
  research clearly locked).
- URLs live in one place (`DemoConfig` constants), empty URL → button hidden.

### 5. Google Sheet backend (user, 30 min)
1. New Google Sheet "Voidle demo signups", header row: `time | email | played_min | source`.
2. Extensions → Apps Script, paste:

```javascript
function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var email = String(data.email || "").trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return ContentService.createTextOutput("bad email");
  }
  SpreadsheetApp.getActiveSpreadsheet().getSheets()[0]
    .appendRow([new Date(), email, data.played_min || "", data.source || "itch-web"]);
  return ContentService.createTextOutput("ok");
}
```

3. Deploy → New deployment → Web app → Execute as **Me**, access **Anyone**.
4. Paste the `/exec` URL into `signup_url` in `res://resources/demo/demo_config.tres`.

### 6. First-Moon-city moment
A short celebration banner when the first lunar City is founded ("First step
on the Moon") — the demo's emotional peak shouldn't pass silently.

### 7. Browser playtest
- One full run, new game → ending, in the browser build. Write down: total
  time, where you waited for Science, anything confusing, console errors.
- Target: 45–75 min. Longer → apply the research pricing pass (cheaper building
  nodes, steeper main path) and quest rewards.

### 8. itch.io upload
- Zip the contents of `Builds/Web/` (index.html at the zip root).
- Kind: HTML, "This file will be played in the browser".
- Viewport 1280×720, **Fullscreen button** on, "Mobile friendly" off.
- SharedArrayBuffer: off (no-threads build).
- Page text: "Browser demo — progress isn't saved; refreshing starts over."

## Needed from the user
- Steam page URL (or "no Steam page yet" → the email form alone).
- The Apps Script `/exec` URL (block 5).
- A playtest slot (block 7).

## Order for the day
Morning: 1 → 2 → 3. Afternoon: 4 + 5 in parallel → 6 → 7 → fixes → 8.
Block 1 decides the day: if a shader or performance problem shows up, it
comes before everything else.
