class_name ClockUI
extends TextureRect

## The day's clock face. Its tooltip, like the day label's, keeps updating while open
## (see tooltip_source), so it always shows the current time.

@onready var clock_hand : Control = $ClockHandTextureRect

var tooltip_source : Callable


## A fixed key, so Godot keeps the tooltip open while its text updates (see LiveTooltipLabel).
func _get_tooltip(_at_position : Vector2) -> String:
	return LiveTooltipLabel.LIVE_TOOLTIP_KEY if tooltip_source.is_valid() else ""


func _make_custom_tooltip(_for_text : String) -> Object:
	return TooltipFactory.make_live_tooltip(tooltip_source)


func _process(_delta: float) -> void:
	if clock_hand == null:
		return
		
	var progress: float = TimeManager.get_day_progress()
	
	clock_hand.rotation = progress * 2.0 * PI
