class_name CounterHoverArea
extends Area2D

## A cellar object that glows under the mouse and opens something when clicked. Subclasses
## say which signals those are.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15

var current_tween : Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	_connect_covering_views()
	modulate = HIDDEN_COLOR


## The shop and brewery views lie over the counter, so it takes no hover meanwhile.
func _connect_covering_views() -> void:
	GUISignals.bar_view_exited.connect(_set_covered.bind(true))
	GUISignals.bar_view_entered.connect(_set_covered.bind(false))


func _hover_changed(_is_entered : bool) -> void:
	pass


func _clicked() -> void:
	pass


func _on_mouse_entered() -> void:
	_glow_to(HOVER_GLOW_COLOR, Tween.EASE_OUT)
	_hover_changed(true)


func _on_mouse_exited() -> void:
	_glow_to(HIDDEN_COLOR, Tween.EASE_IN)
	_hover_changed(false)


func _glow_to(color : Color, ease_type : Tween.EaseType) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", color, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(ease_type)


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_clicked()


func _set_covered(covered : bool) -> void:
	input_pickable = not covered
	if covered:
		_on_mouse_exited()
