# Systems

Reusable systems, one folder each, that can be copied into another project.

The rule: a system contains only its own scripts and scenes and never references the game.
Its interface is a few methods and signals. The one place that knows the project is its
`*_wiring.gd` file, which connects the project's own signals to that interface. That file is
what you edit after copying the system.

`python tools/check_systems.py` enforces the rule.

| System | What it is |
|---|---|
| `dialog/` | Speech bubbles and floating popups (has a wiring file) |
| `console/` | Dev console: log, command line, command registry (has a wiring file) |
| `toast/` | Banner and toast presentation: flash, hold, fade, stacking |
| `tooltip/` | Tooltips that wrap instead of clipping off-screen |
| `toolkit/` | Small helpers: resource folder loading, weighted picker, label pulse, collapsible section |
