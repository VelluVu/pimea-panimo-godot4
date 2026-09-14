class_name RecipeShelfHoverArea
extends Area2D

## In-world "hover and light up" trigger for the recipe library — a small
## wall shelf (ShelfPlank) holding a row of the game's existing beer
## bottle sprite (Bottle1..4, same res://assets/textures/beer_bottle_8x8.png
## and 3x scale Customer.gd already uses for the held-bottle sprite, so it
## reads consistently with the rest of the game's pixel scale). Mirrors
## BreweryHoverArea/WarehouseHoverArea's exact glow/click pattern — see
## those for the established convention — rather than a floating UI
## button, per the push to make more of the panel-opening buttons feel
## like part of the room instead of screen-edge chrome.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15

var current_tween : Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	modulate = HIDDEN_COLOR


func _on_mouse_entered() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	GUISignals.mouse_entered_recipe_shelf_hover_area.emit(true)


func _on_mouse_exited() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", HIDDEN_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	GUISignals.mouse_entered_recipe_shelf_hover_area.emit(false)


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GUISignals.recipe_library_requested.emit()
