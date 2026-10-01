# Save system

One saved `Resource` in one file. Writes are crash-safe (temp file, then backup, then rename),
reads fall back to the backup, and each save carries a version so old saves can be migrated and
saves from a newer build are refused.

## Interface (`SaveSlot`)

| Call | What it does |
|---|---|
| `save_game()`, `load_game()` | Override in the wiring: what to save, and where the loaded resource goes |
| `write(resource)` | Stamps `version` into `version_property` and writes. False on failure, old save kept |
| `read()` | The save (or its backup), migrated to `version`. Null if missing, unreadable or newer |
| `has_save()`, `delete_save()` | Delete also removes the backup and any temp file |
| `_migrate(resource, from_version)` | Override: one step per version bump |

Settings: `save_path`, `version`, `version_property` (an int property on the saved resource;
missing reads as 0) and `save_on_quit` (calls `save_game()` when the window closes).

`SaveFile` holds the static file handling and works on its own.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`save_wiring.gd`**: the path and version in `_init()`, what `save_game()` saves and
   what `load_game()` does with the result, and any signals that should delete the save.
3. Register an autoload whose script is `save_wiring.gd`, or a two-line script that extends
   `SaveWiring` (this game's `src/autoload/save_manager.gd`).

## Files

`save_file.gd` crash-safe file handling, `save_slot.gd` the interface, `save_wiring.gd` the
project's run save. Tests: `tests/test_save_file.gd`, `tests/test_save_slot.gd`.
