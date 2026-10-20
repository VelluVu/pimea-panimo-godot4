# Toast system

Passive text and cards that appear, hold and fade out, with no input and no game state.

## Interface

| Class | What it does |
|---|---|
| `BannerPresenter.new(label, flash_s, hold_s, fade_s, bright_flash, fit_to_text, hide_when_done, on_finished)` | Presents one Label; `present(text)`, `dismiss_early()`, `is_running()` |
| `ToastStack.new(template_label, flash_s, hold_s, fade_s)` | Stacks toasts under each other so a burst is never overwritten; `show_toast(text)` |
| `BannerQueue.new()` | Several presenters that share one spot take turns; `show(presenter, text, on_shown)` queues and starts the next when the current one fades out (`BannerPresenter.finished`) |
| `PopupCardStack` (a Control) | Boxed cards with an icon, heading and text that rise in at the control's position, drift up and fade; a burst queues. `show_card(icon, heading, text)`. Runs in real time and while the tree is paused; never takes the mouse. Tune `hold_seconds`, `max_visible`, `card_width`, `card_style` |
| `ToastStack.max_visible` | Caps the stack; a new toast makes the oldest fade out early (0 = no cap) |
| `ToastStack.hold_per_character`, `min_hold_seconds`, `max_hold_seconds` | Longer text holds longer, within the bounds |

## Use it in a new project

Copy this folder to your project (keep the `.uid` files, so scene references still resolve) and construct the classes from your own UI code.
The label passed in must already be in the scene tree. With `fit_to_text`, anchor its top and
bottom at 0.5 (it grows both ways around the centre) or at 1 (it grows upward from its bottom
edge). No wiring file is needed: nothing here listens to any signal.
