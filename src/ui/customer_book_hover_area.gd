class_name CustomerBookHoverArea
extends Area2D

## In-world trigger for the Asiakaskirja: a small notebook lying on the counter.
## Same glow and click pattern as ReceiptMachineHoverArea.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15

var current_tween : Tween


func _ready() -> void:
	add_to_group(TouchHints.GROUP)
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	input_event.connect(_on_input_event)
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
