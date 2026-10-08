# Toolkit

Small independent helpers that need nothing else.

| Class | What it does |
|---|---|
| `ResourceFolder.load_all(folder, script)` | Loads every `.tres` of one script type from a folder, also in exported builds |
| `WeightedPicker.pick(items, weights)` | Weighted random choice, with an injectable roll for tests |
| `LabelPulse.new(label, pivot)` | A looping grow-and-shrink pulse; `set_active(bool)`; `PIVOT_RIGHT` for a label flush to the right edge |
| `CollapsibleSection.new(container, header_label)` | An arrow button beside a header; `collapsed` and a `toggled` signal |
| `SliderStepper.wrap(slider)` | Big - and + buttons around a slider (hold to repeat) and a larger knob, for touch |

Copy the folder to your project (keep the `.uid` files, so scene references still resolve). No wiring file is needed.
