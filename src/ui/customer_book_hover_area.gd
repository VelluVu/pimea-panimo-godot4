class_name CustomerBookHoverArea
extends Area2D

## Hover-and-glow trigger for the Asiakaskirja, a notebook on the counter.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15

var current_tween : Tween


func _ready() -> void:
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	input_event.connect(_on_input_event)
	GUISignals.bar_view_exited.connect(_set_covered.bind(true))
	GUISignals.bar_view_entered.connect(_set_covered.bind(false))
	modulate = HIDDEN_COLOR


func _on_hover_changed(is_entered : bool) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", HOVER_GLOW_COLOR if is_entered else HIDDEN_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE)
	GUISignals.mouse_entered_customer_book_hover_area.emit(is_entered)


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GUISignals.customer_book_requested.emit()


## The shop and brewery views lie over the counter, so it takes no hover meanwhile.
func _set_covered(covered : bool) -> void:
	input_pickable = not covered
	if covered:
		_on_hover_changed(false)
