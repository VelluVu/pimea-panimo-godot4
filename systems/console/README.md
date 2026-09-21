# Console system

A collapsible, resizable console panel: a running log and a command line, with a command
registry, developer-only commands, and command sets that group commands by domain.

## Interface

| Call | What it does |
|---|---|
| `DevConsole.log_line(bbcode)` | Appends a line to the log |
| `DevConsole.registry.register(name, handler, usage, note, dev_only, listed)` | Adds a command; the handler receives the arguments as a `PackedStringArray` |
| `DevConsole.registry.add_command_set(set)` | Adds a `ConsoleCommandSet` (a group of commands with its own `register()`) |
| `DevConsole.registry.developer_mode_check` | A Callable returning whether dev-only commands may run (default: always) |
| `DevConsole.open_action` / `cancel_action` | InputMap actions that open and focus the console, and close it (empty = unused) |
| `DevConsole.is_console_active()` | True while open or focused, so your own shortcuts can back off |

`clear` and `help` are built in. The registry's wording (unknown command, help headers) is a set of
`var`s with English defaults.

## Use it in a new project

1. Copy this folder to `res://systems/console/`.
2. Instance `console_panel.tscn` in your UI (it anchors to the bottom-right corner).
3. Edit **`console_wiring.gd`**, the only project-specific file: register your commands and
   command sets, set the developer-mode check and the two input actions, connect the signals you
   want in the log, and replace the wording. In this game it also loads the gitignored cheat sets
   and listens to `BrewerySignals`.

Run `python tools/check_systems.py` in the game project to see exactly which project things the
wiring file uses.

## Files

`dev_console.gd` the panel, `console_panel.tscn` its scene, `console_command_registry.gd` dispatch
and help, `console_command.gd` one command, `console_command_set.gd` the base of a command group,
`console_wiring.gd` the project's side. Tests: `tests/test_console_command_registry.gd`.
