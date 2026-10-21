class_name BreweryLampSwitch
extends Node

## Keeps the brewery's tube light, and its bleed through the arch, off until the player
## looks in: on while the doorway is hovered or the brewery view is open, off again when
## neither holds; they start like a tube.

@export var lamp_paths : Array[NodePath] = []

var _lamps : Array[LightFlicker] = []
var _hovered : bool = false
var _open : bool = false


func _ready() -> void:
	for path : NodePath in lamp_paths:
		var lamp := get_node(path) as LightFlicker
		lamp.set_switched_on(false)
		_lamps.append(lamp)
	GUISignals.mouse_entered_brewery_hover_area.connect(_set_hovered)
	GUISignals.brewery_view_opened.connect(_set_open.bind(true))
	GUISignals.brewery_view_closed.connect(_set_open.bind(false))


func _set_hovered(hovered : bool) -> void:
	_hovered = hovered
	_refresh()


func _set_open(open : bool) -> void:
	_open = open
	_refresh()


func _refresh() -> void:
	for lamp : LightFlicker in _lamps:
		lamp.set_switched_on(_hovered or _open, true)
