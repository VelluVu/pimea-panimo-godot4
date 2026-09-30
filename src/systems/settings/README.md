# Settings system

Persisted player preferences: a volume and mute per audio bus, and fullscreen. Applied straight
to `AudioServer` and `DisplayServer`, saved to a `ConfigFile`.

## Interface (`SettingsStore`)

| Call | What it does |
|---|---|
| `get_volume(bus)`, `set_volume(bus, value)` | Linear 0 to 1. Applies at once; does not save |
| `is_muted(bus)`, `set_muted(bus, value)` | Applies and saves |
| `fullscreen`, `set_fullscreen(value)` | Applies and saves |
| `save_settings()` | Call when a slider drag ends, not on every tick |

The file keeps `<bus>_volume` and `<bus>_muted` in `[audio]` and `fullscreen` in `[video]`.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`settings_wiring.gd`**: the bus names from your bus layout, the default volume and
   which buses start muted.
3. Register an autoload whose script is `settings_wiring.gd`, or a two-line script that extends
   `SettingsWiring` (this game's `src/autoload/settings_manager.gd`).

## Files

`settings_store.gd` the interface, `settings_wiring.gd` the project's buses.
Tests: `tests/test_settings_store.gd`.
