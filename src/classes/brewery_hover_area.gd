class_name BreweryHoverArea
extends Area2D


@onready var overlay_glow_sprite: Sprite2D = $Sprite2D

const HOVER_GLOW_COLOR = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS = 0.15

var current_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	if overlay_glow_sprite:
		overlay_glow_sprite.self_modulate = HIDDEN_COLOR


func _on_mouse_entered() -> void:
	print("BreweryHoverArea: Mouse entered")
	if overlay_glow_sprite == null: return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "self_modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	print("Mouse exited brewery hover area")
	if overlay_glow_sprite == null: return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "self_modulate", HIDDEN_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_instance_valid(GUISignals):
			GUISignals.brewery_view_requested.emit()
