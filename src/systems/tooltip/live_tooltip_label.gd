class_name LiveTooltipLabel
extends TooltipLabel

## A TooltipLabel whose text keeps updating while the tooltip is open, for values that
## change every second (a clock). Set tooltip_source to a Callable returning the text.

## Reported to Godot instead of the live text: a tooltip whose text changes is closed
## and reopened, which flickers. Never shown, see TooltipFactory.make_live_tooltip().
const LIVE_TOOLTIP_KEY : String = "live"

var tooltip_source : Callable


func _get_tooltip(_at_position : Vector2) -> String:
	return LIVE_TOOLTIP_KEY if tooltip_source.is_valid() else tooltip_text


func _make_custom_tooltip(for_text: String) -> Object:
	if tooltip_source.is_valid():
		return TooltipFactory.make_live_tooltip(tooltip_source)
	return super._make_custom_tooltip(for_text)
