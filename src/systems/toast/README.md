# Toast system

Passive text that flashes in, holds and fades out, with no input and no game state.

## Interface

| Class | What it does |
|---|---|
| `BannerPresenter.new(label, flash_s, hold_s, fade_s, bright_flash, fit_to_text, hide_when_done, on_finished)` | Presents one Label; `present(text)`, `dismiss_early()`, `is_running()` |
| `ToastStack.new(template_label, flash_s, hold_s, fade_s)` | Stacks toasts under each other so a burst is never overwritten; `show_toast(text)` |

## Use it in a new project

Copy this folder to your project (keep the `.uid` files, so scene references still resolve) and construct the classes from your own UI code.
The label passed in must already be in the scene tree, and anchored with top and bottom at
0.5 if you use `fit_to_text`. No wiring file is needed: nothing here listens to any signal.
