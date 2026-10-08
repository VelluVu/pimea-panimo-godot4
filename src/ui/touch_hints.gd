class_name TouchHints
extends Node

## Touch screens have no hover, so the cellar's clickable spots never glow or show their
## names. On a touch screen this lights them all up for a moment each time the bar view
## shows. Hotspots join GROUP and are lit through their own mouse_entered/mouse_exited.

const GROUP : StringName = &"touch_hint_hotspot"
const SHOW_SECONDS : float = 2.5
## Lets the view switch settle first, so a hotspot under the finger is not lit twice.
const DELAY_SECONDS : float = 0.4

var _run_id : int = 0


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	GUISignals.bar_view_entered.connect(_show_hints)


func _show_hints() -> void:
	_run_id += 1
	var my_run : int = _run_id
	await get_tree().create_timer(DELAY_SECONDS).timeout
	if my_run != _run_id:
		return
	_set_lit(true)
	await get_tree().create_timer(SHOW_SECONDS).timeout
	if my_run == _run_id:
		_set_lit(false)


func _set_lit(lit : bool) -> void:
	for hotspot : Node in get_tree().get_nodes_in_group(GROUP):
		if hotspot is CanvasItem and not (hotspot as CanvasItem).is_visible_in_tree():
			continue
		if lit:
			hotspot.mouse_entered.emit()
		else:
			hotspot.mouse_exited.emit()
