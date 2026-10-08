class_name TouchHints
extends Node

## Touch screens have no hover, so the cellar's clickable spots never show their names.
## On a touch screen the names show for a moment when a run starts and at the start of
## each day, once the cellar is in view (after the day recap closes). Names only: the
## hover glow would read as the finger touching something.

const SHOW_SECONDS : float = 2.5
## Lets a view switch or a closing window settle first.
const DELAY_SECONDS : float = 0.4

## Set at run start and each new day; the next time the bar is in view, the hints show.
var _pending : bool = true
var _run_id : int = 0


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	TimeManager.day_changed.connect(func(_day : int) -> void: _pending = true)
	GUISignals.bar_view_entered.connect(_show_if_pending)
	GUISignals.window_closed.connect(_show_if_pending)


func _show_if_pending() -> void:
	if not _pending:
		return
	_pending = false
	_run_id += 1
	var my_run : int = _run_id
	await get_tree().create_timer(DELAY_SECONDS).timeout
	if my_run != _run_id:
		return
	GUISignals.touch_hints_shown.emit(true)
	await get_tree().create_timer(SHOW_SECONDS).timeout
	if my_run == _run_id:
		GUISignals.touch_hints_shown.emit(false)
