# Tooltip system

Godot's default tooltip never wraps, so a long line can clip off-screen. These build a custom
tooltip that wraps at `TooltipFactory.MAX_WIDTH`.

## Interface

- `TooltipFactory.make_wrapped_tooltip(text)` returns the tooltip Control. Opt in from any Control
  with `func _make_custom_tooltip(for_text): return TooltipFactory.make_wrapped_tooltip(for_text)`.
- `TooltipLabel`, `TooltipButton`, `TooltipProgressBar` are the same thing ready-made: use them
  instead of `Label.new()` and so on, or attach with `node.set_script(TooltipLabel)`.

## Use it in a new project

Copy this folder to your project (keep the `.uid` files, so scene references still resolve). It is styled by the theme type variations
`TooltipPanel` and `TooltipLabel` if your theme defines them, and works without them.
No wiring file is needed.
