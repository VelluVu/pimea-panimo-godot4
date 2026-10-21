# Toolkit

Small independent helpers that need nothing else.

| Class | What it does |
|---|---|
| `ResourceFolder.load_all(folder, script)` | Loads every `.tres` of one script type from a folder, also in exported builds |
| `WeightedPicker.pick(items, weights)` | Weighted random choice, with an injectable roll for tests |
| `LabelPulse.new(label, pivot)` | A looping grow-and-shrink pulse; `set_active(bool)`; `PIVOT_RIGHT` for a label flush to the right edge |
| `CollapsibleSection.new(container, header_label)` | An arrow button beside a header; `collapsed` and a `toggled` signal |
| `SliderStepper.wrap(slider)` | Big - and + buttons around a slider (hold to repeat) and its theme knob scaled up in whole steps, for touch |
| `OptionStepper.wrap(option_button)` | < and > buttons around an OptionButton; skips disabled items, wraps around |
| `PixelStepTween.move(tween, node, from, to, seconds, step)` | Tweens a Node2D's global position in whole steps (one pixel of scaled-up art) instead of gliding through fractions |

Copy the folder to your project (keep the `.uid` files, so scene references still resolve). No wiring file is needed.
