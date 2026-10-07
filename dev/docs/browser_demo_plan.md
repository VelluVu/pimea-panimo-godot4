# Browser demo plan

A playable web build to link from GitHub Pages and itch.io. Not started; this is the
checklist for when it is. Facts checked 2026-10-07.

## Already in place

- Godot 4.7 with the GL Compatibility renderer (`project.godot`), which is what the web
  export uses. No renderer change needed.
- No `export_presets.cfg` yet.
- Assets are about 18 MB, mostly music (OGG/MP3). The web build downloads all of it at start.

## Decided (2026-10-07)

1. **Demo limits: a shorter taste.** The season ends at **day 5** (about 25 minutes) with a
   "Kiitos pelaamisesta! Koko peli tulossa" screen showing the score. Olutoppi talents can be
   seen but not bought. Everything else as in the full game: all customers, styles and events
   that turn up in 5 days. The rules sit behind `OS.has_feature("demo")`.
2. **Hosting: itch.io and GitHub Pages.** itch.io is the public page people are sent to (the
   developer makes the account and page); GitHub Pages builds automatically from the repo for
   the README link and testing. The repo is public, so Pages is free. The public source means
   the limit only stops normal players; fine for now, revisit before a Steam release.
3. **Leaderboard: local.** It works in the browser as is. The online board waits until the
   Steam page is paid for (see the Supabase plan).

## Build steps

1. Install the Web export templates for Godot 4.7 (Editor > Manage Export Templates).
2. Add a **Web** export preset:
   - Thread support **off**. Then no COOP/COEP headers are needed, so it runs on itch.io and
     GitHub Pages as is.
   - Exclude from the export: `addons/godot_ai/`, `addons/sound_board/`, `dev/`, `tests/` and the
     gitignored cheat sets in `src/console/` (`*_cheat_commands.gd`, `dev_mode_commands.gd`).
   - A custom feature tag **`demo`** on the preset.
3. Demo limits in code read `OS.has_feature("demo")`, so the full game and the demo come from
   the same branch. One small rules class holds the limits, with a test.
4. Commit `export_presets.cfg` (it holds no secrets for a Web preset).

## Check in the browser

- **Audio:** browsers start sound only after the first click. The main menu music must start
  then, not fail silently (AudioWiring plays the menu track on start).
- **Saves:** `user://` lives in the browser's IndexedDB. Check that the run save, settings,
  `meta_progress.cfg`, achievements and the leaderboard survive a page reload.
- **Window:** the game is 640x360 with viewport stretch; check scaling and fullscreen in a page.
- **Speed:** shaders (lighting, CanvasModulate), many customers at once, the 400-line console.
- **Input:** keyboard shortcuts that the browser also uses (F11, Escape, Ctrl+keys).
- **Quit button:** does nothing in a browser; hide it on web (`OS.has_feature("web")`).

## Checked in headless Chrome (2026-10-07, dev/tools/web/web_smoke.py)

- Loads to the main menu with no console errors; Quit is hidden.
- New game, the in-game menu (Escape), saving through "Päävalikkoon", and after a page
  reload "Jatka peliä" appears and continues the run.
- Not checkable headless, left for a person: sound after the first click, the day-5 end
  screen in a real 25-minute session, fullscreen, and how it feels.

## Publish

- GitHub Pages: `.github/workflows/web-demo.yml` exports headless (Godot 4.7.2 + templates)
  and deploys to Pages, on demand (Actions tab, "Web demo", Run workflow) or on a `demo-*`
  tag. One-time setup: Settings > Pages > Source "GitHub Actions". The page is then
  https://velluvu.github.io/pimea-panimo-godot4/. A fresh clone exports clean (checked
  2026-10-07; the first import logs parse errors while the class cache is built, harmless).
- itch.io: `butler push build/web <user>/pimea-panimo:html5`, as an HTML game with the
  "SharedArrayBuffer" option off (threads are off).
