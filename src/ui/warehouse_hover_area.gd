class_name WarehouseHoverArea
extends Area2D


const HOVER_GLOW_COLOR = Color(1.3, 1.15, 0.8, 1.0)
const BASE_COLOR = Color(0.0, 0.0, 0.0, 1.0)
const TWEEN_DURATION_SECONDS = 0.15
## A brewed batch going into storage floats up from the door.
const STORED_POPUP_FORMAT : String = "%s: +%d annosta"
const STORED_POPUP_COLOR : Color = Color(1.0, 0.78, 0.35, 1)
## From the middle of the doorway, below where the shop door's notes rise.
const STORED_POPUP_OFFSET : Vector2 = Vector2(-5.0, 20.0)

@onready var overlay_glow_sprite: Polygon2D = get_parent().get_node("WarehouseGlow") as Polygon2D

var current_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	BrewerySignals.batch_stored.connect(_on_batch_stored)

	if is_instance_valid(overlay_glow_sprite):
		overlay_glow_sprite.modulate = BASE_COLOR


func _on_batch_stored(style_name: String, bottles: int) -> void:
	GUISignals.world_popup_requested.emit(tr(STORED_POPUP_FORMAT) % [tr(style_name), bottles], STORED_POPUP_COLOR, global_position + STORED_POPUP_OFFSET)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GUISignals.warehouse_door_clicked.emit()


func _on_mouse_entered() -> void:
	GUISignals.mouse_entered_warehouse_hover_area.emit(true)

	if not is_instance_valid(overlay_glow_sprite): return

	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	GUISignals.mouse_entered_warehouse_hover_area.emit(false)

	if not is_instance_valid(overlay_glow_sprite): return

	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(overlay_glow_sprite, "modulate", BASE_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
