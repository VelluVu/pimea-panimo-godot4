# Input system

Rebindable keyboard shortcuts. Registers its actions in `InputMap` at runtime (the project
settings stay untouched), saves rebindings to their own file and turns unhandled presses into
signals, so scenes never test raw keycodes. Includes a ready-made settings tab for rebinding.

## Interface (`InputBindings`)

| Member | What it does |
|---|---|
| `cancel_pressed` | The fixed cancel key (Esc) was pressed. Never rebindable |
| `shortcut_pressed(action)` | A rebindable action outside `direct_actions` was pressed |
| `bindings_changed` | A key was rebound or reset |
| `rebind(action, keycode)` | Binds and saves; returns the action already using that key, or `&""` |
| `reset_to_defaults()` | Restores `default_keys` and saves |
| `get_action_label(action)`, `get_binding_text(action)`, `get_keycode(action)` | For UI and hints |

`KeyBindingsTab` is a `VBoxContainer` listing every action with its key. Call
`setup(bindings)` before adding it, and forward key presses to `try_capture(event)` from the
owner's `_input()` (the tab may sit in a window that pauses the tree).

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`input_wiring.gd`**: the action names, default keys, labels and the tab's wording.
3. Register an autoload whose script is `input_wiring.gd`, or a two-line script that extends
   `InputWiring` (this game's `src/autoload/input_manager.gd`).

## Files

`input_bindings.gd` the interface, `input_wiring.gd` the project's actions,
`key_bindings_tab.gd` the rebinding UI. Tests: `tests/test_input_bindings.gd`.
