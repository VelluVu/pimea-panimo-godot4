class_name GameSpeedButton
extends Button

## Cycles the game speed (see GameSpeed). Processes while paused to drop back to 1x under a
## pause. At 1x it leaves Engine.time_scale alone, so the playtest bots keep their own.

const SPEED_FORMAT : String = "%dx"
const SPEED_TOOLTIP : String = "Pelin nopeus."

var _index : int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tooltip_text = SPEED_TOOLTIP
	pressed.connect(cycle)
	_refresh()


func _process(_delta : float) -> void:
	if _index != 0:
		_apply(GameSpeed.time_scale(_index, get_tree().paused))


func _exit_tree() -> void:
	if _index != 0:
		_apply(1.0)


## The next speed; the button and its shortcut both land here.
func cycle() -> void:
	_index = GameSpeed.next_index(_index)
	if _index == 0:
		_apply(1.0)
	_refresh()


func _apply(speed : float) -> void:
	Engine.time_scale = speed
	GameSpeed.player_speed = speed


func _refresh() -> void:
	text = SPEED_FORMAT % roundi(GameSpeed.SPEEDS[_index])
