class_name FocusPause
extends Node

## Pauses the run while the window is out of focus (alt-tab, another browser tab), unless the
## player turned it off. Through PauseLock, so coming back never unpauses an open window.

var _holding : bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what : int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not _holding:
		if SettingsManager.get_option(SettingsManager.OPTION_PAUSE_ON_FOCUS_LOSS):
			_holding = true
			PauseLock.hold(self)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _holding:
		_holding = false
		PauseLock.release(self)
