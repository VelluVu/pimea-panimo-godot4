class_name ClockUI
extends TextureRect


@onready var clock_hand : Control = $ClockHandTextureRect


func _process(_delta: float) -> void:
	if clock_hand == null:
		return
		
	var progress = TimeManager.get_day_progress()
	
	clock_hand.rotation = progress * 2.0 * PI
