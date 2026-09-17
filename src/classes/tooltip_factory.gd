class_name TooltipFactory
extends RefCounted

## Godot's default tooltip (used by every Control.tooltip_text in this
## project) only repositions itself to stay inside the viewport — it never
## wraps or resizes the Label, so a long single-line description (e.g. an
## ingredient's stat blurb) can render wider than the game's own 640px base
## viewport (see project.godot's viewport_width) and clip off-screen. Same
## "free text vs a box sized for the typical case" bug as the speech-bubble/
## toast/banner fixes in dialog_view.gd/sale_flash_toast.gd/gui.gd, just for
## tooltips — fixed here by handing back a custom tooltip Control instead of
## letting the engine build its own.
##
## Any Control with a tooltip_text can opt in with:
##   func _make_custom_tooltip(for_text: String) -> Object:
##       return TooltipFactory.make_wrapped_tooltip(for_text)
const MAX_WIDTH: float = 260.0


static func make_wrapped_tooltip(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"TooltipPanel"

	var label := Label.new()
	label.theme_type_variation = &"TooltipLabel"
	label.text = text

	# Only force wrapping/width once the text actually needs it — a short
	# tooltip ("3 kg") should stay its natural tight size, not always
	# balloon out to MAX_WIDTH.
	if label.get_minimum_size().x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = MAX_WIDTH

	panel.add_child(label)
	return panel
