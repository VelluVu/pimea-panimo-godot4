class_name TooltipFactory
extends RefCounted

## Godot's default tooltip never wraps, so a long line can render wider than the viewport
## and clip off-screen. This builds a custom tooltip that wraps at MAX_WIDTH, styled by the
## theme type variations TooltipPanel and TooltipLabel if the project defines them.
## Any Control with a tooltip_text opts in with:
##   func _make_custom_tooltip(for_text: String) -> Object:
##       return TooltipFactory.make_wrapped_tooltip(for_text)
const MAX_WIDTH: float = 260.0


static func make_wrapped_tooltip(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"TooltipPanel"

	var label := Label.new()
	label.theme_type_variation = &"TooltipLabel"
	label.text = text

	# Wrap only when the text needs it, so a short tooltip keeps its tight size.
	if label.get_minimum_size().x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = MAX_WIDTH

	panel.add_child(label)
	return panel
