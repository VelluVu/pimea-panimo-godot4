# Mobile port plan

Make the browser demo play well on phones, then reuse the work for an Android app later.
Started 2026-10-08.

## Decided (2026-10-08)

1. **Target: mobile browser first.** The itch.io / GitHub Pages demo on phones. No store, SDK
   or fees yet; every touch fix carries over to an Android build later.
2. **One touch-first UI.** Bigger buttons, rows and text for everyone, PC included. One layout
   to build and test.
3. **Landscape only.** The scene stays 640x360; only the UI changes.

## Findings (phone emulation, Pixel 7 landscape, 915x412 CSS px)

`python dev/tools/web/web_smoke.py --phone` emulates the phone with touch input
(`tap X Y`, `hold X Y SECONDS`). Game pixel to CSS pixel: x = 91 + 1.14 * gx, y = 1.14 * gy.

- **Taps already work** as left clicks: menus, the shop and brewery doors, buttons.
- **No tooltips on touch.** Holding a label shows nothing. 30 scripts use tooltips (money,
  LVV risk, clock, level, batch quality wishes, ingredients, perks).
- **No hover glow.** 16 scripts (61 connections) react to the mouse; on touch the "this is
  clickable" highlight never shows.
- **Targets too small.** A touch target should be about 44-48 dp; on this phone 1 game px is
  about 1.14 dp, so about **40 game px**. Today: shop Myy/Osta about 20 game px tall, shop tabs
  about 16, goals toggle 16x12, options cog 32. Text is mostly 11-16 px (3-4 mm).
- **Black bars.** A 20:9 phone shows about 20% black at the sides (stretch aspect "keep").
- **Keyboard only:** Esc and the shortcuts P, K, I, T, U. Most windows have a close button.
- **Console** button takes a corner; typing needs the on-screen keyboard.

## Steps

1. **Touch input basics** (small, no layout change). Done 2026-10-08 (`8b3096c`): hold for
   tooltips (`TouchTooltip`), hotspot hints on the bar view (`TouchHints`), console hidden on touch.
   - Press-and-hold opens the tooltip, in `src/systems/tooltip/` so every tooltip gets it;
     a tap elsewhere closes it.
   - Hover glow: on touch devices show the clickable outlines in another way (a short pulse
     at the start of a run, or a faint permanent outline).
   - Hide the console button on touch devices (the gitignored cheats are not in the demo).
   - Every window closable without Esc (check each one has a close button).
2. **Fill the screen**
   - Stretch aspect "expand" so wide phones get more game width instead of bars; anchor the
     UI to the edges and check the scene still covers the extra width.
   - Respect the safe area (notches, rounded corners).
   - A fullscreen button on web (browsers hide their bars only in fullscreen).
3. **Theme pass**: minimum sizes in `main_theme.tres` (buttons, option buttons, sliders, tabs,
   check boxes) and a larger base font; then fix what overflows.
4. **Screen by screen**: top bar, goals panel, shop, brewery, warehouse, then every window
   (recipe library, upgrades, customer book, run effects, receipts, day recap, level-up,
   menus, options). Dense panels may become full-screen sheets with tabs.
5. **Test**: `web_smoke.py --phone` screenshots of every screen, then the developer's own phone
   on the Pages URL (load time of the 40 MB wasm on mobile data, memory, audio, saves).

## Later: Android app

Android SDK + JDK + a signing key, an Android export preset, the Play developer fee. New
personal Play accounts need a closed test with testers before release (check the current
rules). iOS needs a Mac and Apple's yearly fee.
