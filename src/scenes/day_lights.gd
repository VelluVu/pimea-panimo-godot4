class_name DayLights
extends Node

## The night between days: when the day changes the lamps click off one by one and the
## cellar stays dark while the day recap is open; closing it lights them again in reverse,
## the last one off coming back first with a stutter. Lamps step, never fade, like the art.

const OFF_GAP_SECONDS : float = 0.22
const ON_GAP_SECONDS : float = 0.18
const STUTTER_SECONDS : float = 0.07
## The lamps come back by themselves if no window closes, so the cellar never stays dark.
const MAX_NIGHT_SECONDS : float = 10.0
const NIGHT_DARKNESS : Color = Color(0.16, 0.15, 0.2)

@export_node_path("CanvasModulate") var darkness_path : NodePath

## The LightFlicker lamps beside this node, switched off in tree order.
var lamps : Array[LightFlicker] = []
var darkness : CanvasModulate
var _day_darkness : Color
var _night : bool = false
var _sequence : Tween


func _ready() -> void:
	# The recap may pause the tree; the lamps must still switch.
	process_mode = Node.PROCESS_MODE_ALWAYS
	darkness = get_node(darkness_path) as CanvasModulate
	_day_darkness = darkness.color
	for node : Node in get_parent().find_children("*", "PointLight2D"):
		if node is LightFlicker:
			lamps.append(node)
	TimeManager.day_changed.connect(_on_day_changed.unbind(1))
	GUISignals.window_closed.connect(_light_up)


func _on_day_changed() -> void:
	_night = true
	_restart_sequence()
	for lamp : LightFlicker in lamps:
		_sequence.tween_callback(_switch.bind(lamp, 0.0))
		_sequence.tween_interval(OFF_GAP_SECONDS)
	_sequence.tween_callback(_set_darkness.bind(NIGHT_DARKNESS))
	get_tree().create_timer(MAX_NIGHT_SECONDS, true).timeout.connect(_light_up)


func _light_up() -> void:
	if not _night:
		return
	_night = false
	_restart_sequence()
	_sequence.tween_callback(_set_darkness.bind(_day_darkness))
	for i : int in range(lamps.size() - 1, -1, -1):
		var lamp : LightFlicker = lamps[i]
		if i == lamps.size() - 1:
			_sequence.tween_callback(_switch.bind(lamp, 1.0))
			_sequence.tween_interval(STUTTER_SECONDS)
			_sequence.tween_callback(_switch.bind(lamp, 0.0))
			_sequence.tween_interval(STUTTER_SECONDS)
		_sequence.tween_callback(_switch.bind(lamp, 1.0))
		_sequence.tween_interval(ON_GAP_SECONDS)


func _restart_sequence() -> void:
	if _sequence != null:
		_sequence.kill()
	_sequence = create_tween()


func _switch(lamp : LightFlicker, dimmer : float) -> void:
	lamp.dimmer = dimmer


func _set_darkness(color : Color) -> void:
	darkness.color = color
