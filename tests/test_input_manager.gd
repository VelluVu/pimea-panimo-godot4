@tool
extends McpTestSuite

## InputManager's rebinding rules and persistence. A fresh instance with
## _save_path redirected to a throwaway file, so the player's real bindings are
## never read or written. _ready() is not called; actions are registered by hand.

const InputManagerScript := preload("res://src/autoload/input_manager.gd")
const TEST_SAVE_PATH: String = "user://test_input_manager.cfg"


func suite_name() -> String:
	return "input_manager"


func _make_manager() -> Node:
	var manager: Node = track(InputManagerScript.new())
	manager._save_path = TEST_SAVE_PATH
	manager._register_actions()
	return manager


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_actions_start_on_their_default_keys() -> void:
	var manager := _make_manager()
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_TOGGLE_BREWERY), KEY_P)
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_OPEN_CONSOLE), KEY_C)
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_CANCEL), KEY_ESCAPE)


func test_rebind_changes_the_key_and_persists() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputManagerScript.ACTION_TOGGLE_SHOP, KEY_J)
	assert_eq(conflict, &"")
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_TOGGLE_SHOP), KEY_J)

	var reloaded := _make_manager()
	reloaded._load_bindings()
	assert_eq(reloaded.get_keycode(InputManagerScript.ACTION_TOGGLE_SHOP), KEY_J)

	manager.reset_to_defaults()
	_cleanup()


func test_rebind_refuses_a_key_used_by_another_action() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputManagerScript.ACTION_TOGGLE_SHOP, KEY_P)
	assert_eq(conflict, InputManagerScript.ACTION_TOGGLE_BREWERY)
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()


func test_escape_is_reserved() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputManagerScript.ACTION_TOGGLE_SHOP, KEY_ESCAPE)
	assert_eq(conflict, InputManagerScript.ACTION_CANCEL)
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()


func test_reset_restores_every_default() -> void:
	var manager := _make_manager()
	manager.rebind(InputManagerScript.ACTION_TOGGLE_SHOP, KEY_J)
	manager.reset_to_defaults()
	assert_eq(manager.get_keycode(InputManagerScript.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()
