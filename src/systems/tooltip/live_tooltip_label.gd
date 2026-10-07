class_name LiveTooltipLabel
extends TooltipLabel

## A TooltipLabel whose text is built when the tooltip opens, for values that change
## every second (a clock). Set tooltip_source to a Callable returning the text.

var tooltip_source : Callable


func _get_tooltip(_at_position : Vector2) -> String:
	return tooltip_source.call() if tooltip_source.is_valid() else tooltip_text
