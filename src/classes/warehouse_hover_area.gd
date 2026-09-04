class_name WarehouseHoverArea
extends Area2D


const HOVER_GLOW_COLOR = Color(1.3, 1.15, 0.8, 1.0)
const BASE_COLOR = Color(0.0, 0.0, 0.0, 1.0)
const TWEEN_DURATION_SECONDS = 0.15

@onready var overlay_glow_sprite: Polygon2D = get_parent().get_node("WarehouseGlow") as Polygon2D

var current_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if is_instance_valid(overlay_glow_sprite):
		overlay_glow_sprite.modulate = BASE_COLOR


func _on_mouse_entered() -> void:
	GUISignals.warehouse_hovered.emit(true)

	if not is_instance_valid(overlay_glow_sprite): return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func _on_mouse_exited() -> void:
	GUISignals.warehouse_hovered.emit(false)

	if not is_instance_valid(overlay_glow_sprite): return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "modulate", BASE_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)