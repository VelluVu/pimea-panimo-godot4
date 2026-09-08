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
	GUISignals.bar_view_exited.connect(_on_bar_view_exited)
	GUISignals.bar_view_entered.connect(_on_bar_view_entered)

	if overlay_glow_sprite:
		overlay_glow_sprite.self_modulate = HIDDEN_COLOR


func _on_bar_view_exited() -> void:
	input_pickable = false

	if current_tween and current_tween.is_running():
		current_tween.kill()

	if overlay_glow_sprite:
		overlay_glow_sprite.self_modulate = HIDDEN_COLOR


func _on_bar_view_entered() -> void:
	input_pickable = true


func _on_mouse_entered() -> void:
	if overlay_glow_sprite == null: return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "self_modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	GUISignals.mouse_entered_brewery_hover_area.emit(true)


func _on_mouse_exited() -> void:
	if overlay_glow_sprite == null: return
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "self_modulate", HIDDEN_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	GUISignals.mouse_entered_brewery_hover_area.emit(false)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_instance_valid(GUISignals):
			GUISignals.brewery_view_requested.emit()
