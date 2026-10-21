class_name BreweryLampSwitch
extends Node

## Keeps the brewery's tube light off until the player looks in: on while the doorway is
## hovered or the brewery view is open, off again when neither holds; it starts like a tube.

@export_node_path("PointLight2D") var lamp_path : NodePath

var _lamp : LightFlicker
var _hovered : bool = false
var _open : bool = false


func _ready() -> void:
	_lamp = get_node(lamp_path) as LightFlicker
	_lamp.set_switched_on(false)
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
	_lamp.set_switched_on(_hovered or _open, true)
