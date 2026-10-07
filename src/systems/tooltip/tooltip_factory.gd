class_name TooltipFactory
extends RefCounted

## Godot's default tooltip never wraps, so a long line can render wider than the viewport
## and clip off-screen. This builds a custom tooltip that wraps at MAX_WIDTH, styled by the
## theme type variations TooltipPanel and TooltipLabel if the project defines them.
## Any Control with a tooltip_text opts in with:
##   func _make_custom_tooltip(for_text: String) -> Object:
##       return TooltipFactory.make_wrapped_tooltip(for_text)
const MAX_WIDTH: float = 260.0
## How often a live tooltip re-reads its text.
const LIVE_REFRESH_SECONDS: float = 0.25


static func make_wrapped_tooltip(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"TooltipPanel"

	var label := Label.new()
	label.theme_type_variation = &"TooltipLabel"
	label.text = text
	_wrap_if_needed(label)

	panel.add_child(label)
	return panel


## A wrapped tooltip that re-reads `source` (a Callable returning the text) while it is
## open, for values that change every second. The control showing it must report a fixed
## tooltip text: Godot closes and reopens a tooltip whose text changes, which flashes.
static func make_live_tooltip(source: Callable) -> Control:
	var panel: Control = make_wrapped_tooltip(source.call())
	var label: Label = panel.get_child(0)
	var timer := Timer.new()
	timer.wait_time = LIVE_REFRESH_SECONDS
	timer.autostart = true
	# Tooltips also open over paused windows.
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(func() -> void:
		label.text = source.call()
		_wrap_if_needed(label))
	panel.add_child(timer)
	return panel


## Wrap only when the text needs it, so a short tooltip keeps its tight size.
static func _wrap_if_needed(label: Label) -> void:
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = MAX_WIDTH
