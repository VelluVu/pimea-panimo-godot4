class_name TooltipLabel
extends Label

## Plain Label with TooltipFactory's wrapping tooltip wired in — use in
## place of Label.new() for any dynamically-created row/list Label that
## sets tooltip_text, or attach via existing_label.set_script(TooltipLabel)
## to a scene-defined Label without editing its .tscn.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
