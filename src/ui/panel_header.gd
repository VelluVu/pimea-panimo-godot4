class_name PanelHeader
extends RefCounted

## Puts a window's title in a framed bar like the recipe panel's, so the joined brewery or
## shop window has one header style across both halves.

## The recipe panel's CurrentRecipeBar height, so the two bars line up.
const HEIGHT : float = 28.0


## Moves `label` into a new bar at its place and returns the bar.
static func wrap(label : Label) -> Panel:
	var bar := Panel.new()
	bar.custom_minimum_size.y = HEIGHT
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_sibling(bar)
	label.reparent(bar)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return bar
