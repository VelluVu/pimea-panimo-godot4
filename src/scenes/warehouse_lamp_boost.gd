class_name WarehouseLampBoost
extends Node

## Brightens the warehouse's bulb while its door is hovered, in step with the door's glow
## (WarehouseHoverArea), so the lit storeroom answers the pointer.

const HOVER_BOOST : float = 1.4
## As the door's own glow tween.
const TWEEN_SECONDS : float = 0.15

@export_node_path("PointLight2D") var lamp_path : NodePath

var _lamp : LightFlicker
var _tween : Tween


func _ready() -> void:
	_lamp = get_node(lamp_path) as LightFlicker
	GUISignals.mouse_entered_warehouse_hover_area.connect(_on_hover_changed)


func _on_hover_changed(hovered : bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if hovered else Tween.EASE_IN)
	_tween.tween_property(_lamp, "boost", HOVER_BOOST if hovered else 1.0, TWEEN_SECONDS)
