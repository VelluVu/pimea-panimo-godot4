class_name OlutoppiNodeView
extends RefCounted

## The labels inside one Olutoppi node square, and its hover look: a node the player can
## buy right now grows a little and brightens under the mouse.

const HOVER_SCALE : Vector2 = Vector2(1.08, 1.08)
## Above 1.0 so the labels brighten too; warm to match the gold level text.
const HOVER_TINT : Color = Color(1.3, 1.22, 1.05)
const HOVER_TWEEN_SECONDS : float = 0.08

var button : Button
var icon_label : Label
var level_bonus_label : Label

var _hovered : bool = false
var _tween : Tween


func _init(node_button : Button) -> void:
	button = node_button
	icon_label = node_button.get_node("VBox/IconLabel")
	level_bonus_label = node_button.get_node("VBox/LevelBonusLabel")
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_set_hovered.bind(false))


## Call after the button's disabled state changes, so a node that was just bought to
## its max (or can no longer be afforded) drops the hover look under the mouse.
func refresh_availability() -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	if button.disabled:
		_set_hovered(false)


func _on_mouse_entered() -> void:
	if not button.disabled:
		_set_hovered(true)


func _set_hovered(hovered : bool) -> void:
	if hovered == _hovered:
		return
	_hovered = hovered
	button.pivot_offset = button.size * 0.5
	if _tween != null:
		_tween.kill()
	_tween = button.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(button, "scale", HOVER_SCALE if hovered else Vector2.ONE, HOVER_TWEEN_SECONDS)
	_tween.tween_property(button, "modulate", HOVER_TINT if hovered else Color.WHITE, HOVER_TWEEN_SECONDS)
