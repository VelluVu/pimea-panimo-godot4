# Toolkit

Small independent helpers that need nothing else.

| Class | What it does |
|---|---|
| `ResourceFolder.load_all(folder, script)` | Loads every `.tres` of one script type from a folder, also in exported builds |
| `WeightedPicker.pick(items, weights)` | Weighted random choice, with an injectable roll for tests |
| `LabelPulse.new(label)` | A looping grow-and-shrink pulse; `set_active(bool)` |
| `CollapsibleSection.new(container, header_label)` | An arrow button beside a header; `collapsed` and a `toggled` signal |

Copy the folder to `res://systems/toolkit/`. No wiring file is needed.
