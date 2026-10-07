# Settings system

Persisted player preferences: a volume and mute per audio bus, fullscreen, the language and
small named options.
Applied straight to `AudioServer`, `DisplayServer` and `TranslationServer`, saved to a `ConfigFile`.

## Interface (`SettingsStore`)

| Call | What it does |
|---|---|
| `get_volume(bus)`, `set_volume(bus, value)` | Linear 0 to 1. Applies at once; does not save |
| `is_muted(bus)`, `set_muted(bus, value)` | Applies and saves |
| `fullscreen`, `set_fullscreen(value)` | Applies and saves |
| `get_language()`, `set_language(locale)` | The locale in use (saved choice, else system language, else `fallback_locale`). Setting applies, saves and emits `language_changed` |
| `get_option(key, default)`, `set_option(key, value)` | Any small choice another system keeps across sessions. Setting saves |
| `save_settings()` | Call when a slider drag ends, not on every tick |

The file keeps `<bus>_volume` and `<bus>_muted` in `[audio]`, `fullscreen` in `[video]` and
`language` in `[general]` (empty follows the system language), and the options in `[options]`.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`settings_wiring.gd`**: the bus names from your bus layout, the default volume,
   which buses start muted, the `supported_locales` and the `translation_paths` to load.
3. Register an autoload whose script is `settings_wiring.gd`, or a two-line script that extends
   `SettingsWiring` (this game's `src/autoload/settings_manager.gd`).

## Files

`settings_store.gd` the interface, `settings_wiring.gd` the project's buses.
Tests: `tests/test_settings_store.gd`.
