# Browser demo plan

A playable web build to link from GitHub Pages and itch.io. Not started; this is the
checklist for when it is. Facts checked 2026-10-07.

## Already in place

- Godot 4.7 with the GL Compatibility renderer (`project.godot`), which is what the web
  export uses. No renderer change needed.
- No `export_presets.cfg` yet.
- Assets are about 18 MB, mostly music (OGG/MP3). The web build downloads all of it at start.

## Decide first (the developer's call)

1. **Demo limits.** Options: a shorter season (e.g. 7 days instead of 15), some customers,
   styles or Olutoppi talents locked, a "full game coming" screen at the end. Or no limits:
   the whole game as it is now.
2. **Where it is hosted.** GitHub Pages (free, from the repo), itch.io (free, a game page with
   comments), or both.
3. **Leaderboard.** Keep it local in the demo (the planned Supabase online board is not built).

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

## Publish

- GitHub Pages: a GitHub Actions workflow that exports headless (Godot 4.7 + templates) and
  pushes the build to Pages on a tag or on demand.
- itch.io: `butler push build/web <user>/pimea-panimo:html5`, as an HTML game with the
  "SharedArrayBuffer" option off (threads are off).
