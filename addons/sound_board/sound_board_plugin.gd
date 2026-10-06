@tool
extends EditorPlugin

const SoundBoardDock := preload("sound_board_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = SoundBoardDock.new()
	_dock.name = "Äänet"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.queue_free()
