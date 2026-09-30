@tool
extends McpTestSuite

## InputBindings' rebinding rules and persistence, on the game's InputWiring table. A
## fresh instance with save_path redirected to a throwaway file, so the player's real
## bindings are never read or written. _ready() is not called; actions are registered by hand.

const TEST_SAVE_PATH: String = "user://test_input_bindings.cfg"


func suite_name() -> String:
	return "input_bindings"


func _make_manager() -> InputWiring:
	var manager: InputWiring = track(InputWiring.new())
	manager.save_path = TEST_SAVE_PATH
	manager.register_actions()
	return manager


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_actions_start_on_their_default_keys() -> void:
	var manager := _make_manager()
	assert_eq(manager.get_keycode(InputWiring.ACTION_TOGGLE_BREWERY), KEY_P)
	assert_eq(manager.get_keycode(InputWiring.ACTION_OPEN_CONSOLE), KEY_C)
	assert_eq(manager.get_keycode(InputWiring.ACTION_CANCEL), KEY_ESCAPE)


func test_rebind_changes_the_key_and_persists() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputWiring.ACTION_TOGGLE_SHOP, KEY_J)
	assert_eq(conflict, &"")
	assert_eq(manager.get_keycode(InputWiring.ACTION_TOGGLE_SHOP), KEY_J)

	var reloaded := _make_manager()
	reloaded.load_bindings()
	assert_eq(reloaded.get_keycode(InputWiring.ACTION_TOGGLE_SHOP), KEY_J)

	manager.reset_to_defaults()
	_cleanup()


func test_rebind_refuses_a_key_used_by_another_action() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputWiring.ACTION_TOGGLE_SHOP, KEY_P)
	assert_eq(conflict, InputWiring.ACTION_TOGGLE_BREWERY)
	assert_eq(manager.get_keycode(InputWiring.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()


func test_escape_is_reserved() -> void:
	var manager := _make_manager()
	var conflict: StringName = manager.rebind(InputWiring.ACTION_TOGGLE_SHOP, KEY_ESCAPE)
	assert_eq(conflict, InputWiring.ACTION_CANCEL)
	assert_eq(manager.get_keycode(InputWiring.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()


func test_reset_restores_every_default() -> void:
	var manager := _make_manager()
	manager.rebind(InputWiring.ACTION_TOGGLE_SHOP, KEY_J)
	manager.reset_to_defaults()
	assert_eq(manager.get_keycode(InputWiring.ACTION_TOGGLE_SHOP), KEY_K)
	_cleanup()


func test_every_action_has_a_default_key_and_label() -> void:
	var manager := _make_manager()
	for action: StringName in manager.rebindable_actions:
		assert_true(manager.default_keys.has(action), "no default key: %s" % action)
		assert_true(manager.action_labels.has(action), "no label: %s" % action)


func test_default_keys_are_unique() -> void:
	var manager := _make_manager()
	var seen: Dictionary = {}
	for action: StringName in manager.rebindable_actions:
		var keycode: Key = manager.default_keys[action]
		assert_false(seen.has(keycode), "%s shares its default key" % action)
		seen[keycode] = true
