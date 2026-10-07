class_name ClockUI
extends TextureRect

## The day's clock face. Its tooltip, like the day label's, is built when it opens
## (see tooltip_source), so it always shows the current time.

@onready var clock_hand : Control = $ClockHandTextureRect

var tooltip_source : Callable


func _get_tooltip(_at_position : Vector2) -> String:
	return tooltip_source.call() if tooltip_source.is_valid() else ""


func _make_custom_tooltip(for_text : String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)


func _process(_delta: float) -> void:
	if clock_hand == null:
		return
		
	var progress: float = TimeManager.get_day_progress()
	
	clock_hand.rotation = progress * 2.0 * PI
