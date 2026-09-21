# Dialog system

Speech bubbles (one per slot, stacked so nearby speakers do not overlap, clamped inside the
viewport) and floating popups that drift up and fade. No autoloads, input actions or other
folders needed.

## Interface (`DialogView`)

| Call | What it does |
|---|---|
| `show_bubble(text, slot, speaker_pos, display_time, fade_time)` | Shows or replaces the bubble of `slot` above `speaker_pos` (global) |
| `close_bubble(slot)` | Closes that bubble at once, even mid-fade |
| `show_popup(text, color, global_pos)` | A short floating text |

## Use it in a new project

1. Copy this folder to your project (keep the `.uid` files, so scene references still resolve).
2. Put a full-screen `Control` in your UI and attach `dialog_view.gd` (or `DialogView` as a class).
3. Edit **`dialog_wiring.gd`**, the only project-specific file: connect your own signals to the
   three calls above, and change the popup wording and colors. In this game it listens to
   `BrewerySignals` (`dialogue_pushed`, `customer_evicted`, `xp_popup_requested`, ...).

Everything else works unchanged. Run `python dev/tools/check_systems.py` in the game project to
confirm nothing but the wiring file touches the project.

## Files

`dialog_view.gd` the interface, `dialog_wiring.gd` the project's signals, `bubble_entry.gd`
one bubble's lifecycle, `bubble_layout.gd` placement, `speech_bubble.gd/.tscn` the bubble.
Tests: `tests/test_dialog_view.gd`, `test_bubble_entry.gd`, `test_bubble_layout.gd`.
