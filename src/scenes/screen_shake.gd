class_name ScreenShake
extends Node

## Shakes the world, not the GUI layers, by moving the viewport's canvas: hard when a bar
## fight breaks out, a knock for every glass that shatters. See ShakeRules.

const FIGHT_TRAUMA : float = 0.6
const GLASS_TRAUMA : float = 0.35

var _trauma : float = 0.0


func _ready() -> void:
	# A level-up pauses the tree mid-shake; the world must still settle back.
	process_mode = Node.PROCESS_MODE_ALWAYS
	BrewerySignals.bar_fight_started.connect(_add_trauma.bind(FIGHT_TRAUMA).unbind(1))
	BrewerySignals.glass_shattered.connect(_add_trauma.bind(GLASS_TRAUMA))
	set_process(false)


func _add_trauma(amount : float) -> void:
	if not SettingsManager.get_option(SettingsManager.OPTION_SCREEN_SHAKE):
		return
	_trauma = ShakeRules.added(_trauma, amount)
	set_process(true)


func _process(delta : float) -> void:
	_trauma = ShakeRules.decayed(_trauma, delta)
	_set_offset(ShakeRules.offset(_trauma, randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)))
	if _trauma <= 0.0:
		set_process(false)


func _set_offset(offset : Vector2i) -> void:
	var canvas : Transform2D = get_viewport().canvas_transform
	canvas.origin = Vector2(offset)
	get_viewport().canvas_transform = canvas
