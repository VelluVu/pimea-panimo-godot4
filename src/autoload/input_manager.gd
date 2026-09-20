#InputManager (Autoload)
extends Node

## Single home for the game's keyboard input. Defines every action in Godot's
## InputMap at runtime (project.godot stays untouched), applies the player's
## saved rebindings, and turns unhandled key presses into signals so scenes
## never test raw keycodes. Windows that must react while the tree is paused
## still listen in their own _input(), but ask InputManager for the action name.
##
## Bindings persist in their own file, not settings.cfg: SettingsManager
## rewrites settings.cfg from its own in-memory copy and would drop this section.

## Esc: fixed, not rebindable, so a player can never lock themselves out of the menu.
signal cancel_pressed
## A rebindable shortcut (see REBINDABLE_ACTIONS) was pressed.
signal shortcut_pressed(action: StringName)
signal bindings_changed

const ACTION_CANCEL: StringName = &"menu_cancel"
const ACTION_OPEN_CONSOLE: StringName = &"open_console"
const ACTION_TOGGLE_BREWERY: StringName = &"toggle_brewery"
const ACTION_TOGGLE_SHOP: StringName = &"toggle_shop"
const ACTION_TOGGLE_WAREHOUSE: StringName = &"toggle_warehouse"
const ACTION_TOGGLE_RUN_EFFECTS: StringName = &"toggle_run_effects"
const ACTION_TOGGLE_RECEIPT_LOG: StringName = &"toggle_receipt_log"

## Shown in this order in the settings Input tab. Console first: it is
## _input()-handled by DevConsole itself, not routed through shortcut_pressed.
const REBINDABLE_ACTIONS: Array[StringName] = [
	ACTION_OPEN_CONSOLE,
	ACTION_TOGGLE_BREWERY,
	ACTION_TOGGLE_SHOP,
	ACTION_TOGGLE_WAREHOUSE,
	ACTION_TOGGLE_RUN_EFFECTS,
	ACTION_TOGGLE_RECEIPT_LOG,
]

## Actions that DevConsole (or another _input() listener) reacts to directly.
const DIRECT_ACTIONS: Array[StringName] = [ACTION_OPEN_CONSOLE]

const DEFAULT_KEYS: Dictionary = {
	ACTION_OPEN_CONSOLE: KEY_C,
	ACTION_TOGGLE_BREWERY: KEY_P,
	ACTION_TOGGLE_SHOP: KEY_K,
	ACTION_TOGGLE_WAREHOUSE: KEY_I,
	ACTION_TOGGLE_RUN_EFFECTS: KEY_T,
	ACTION_TOGGLE_RECEIPT_LOG: KEY_U,
}

const ACTION_LABELS: Dictionary = {
	ACTION_OPEN_CONSOLE: "Konsoli",
	ACTION_TOGGLE_BREWERY: "Panimo",
	ACTION_TOGGLE_SHOP: "Kauppa",
	ACTION_TOGGLE_WAREHOUSE: "Varasto",
	ACTION_TOGGLE_RUN_EFFECTS: "Ajon vaikutukset",
	ACTION_TOGGLE_RECEIPT_LOG: "Kuittiloki",
}

const BINDINGS_FILE_PATH: String = "user://input_bindings.cfg"
const SECTION_KEYS: String = "keys"

## Overridable so tests never touch the player's real bindings.
var _save_path: String = BINDINGS_FILE_PATH


func _ready() -> void:
	_register_actions()
	_load_bindings()


## Esc is checked first so it always wins, then each rebindable shortcut.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_CANCEL):
		cancel_pressed.emit()
		get_viewport().set_input_as_handled()
		return

	for action: StringName in REBINDABLE_ACTIONS:
		if DIRECT_ACTIONS.has(action):
			continue
		if event.is_action_pressed(action):
			shortcut_pressed.emit(action)
			get_viewport().set_input_as_handled()
			return


func get_action_label(action: StringName) -> String:
	return ACTION_LABELS.get(action, String(action))


## The key currently bound to `action`, as text for buttons and hints.
func get_binding_text(action: StringName) -> String:
	var keycode: Key = get_keycode(action)
	return OS.get_keycode_string(keycode) if keycode != KEY_NONE else ""


func get_keycode(action: StringName) -> Key:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).keycode
	return KEY_NONE


## Binds `keycode` to `action` and saves. Returns the action that already uses
## that key (nothing changes then), or &"" on success. Esc is reserved.
func rebind(action: StringName, keycode: Key) -> StringName:
	if keycode == KEY_ESCAPE:
		return ACTION_CANCEL
	for other: StringName in REBINDABLE_ACTIONS:
		if other != action and get_keycode(other) == keycode:
			return other

	_apply_key(action, keycode)
	_save_bindings()
	bindings_changed.emit()
	return &""


func reset_to_defaults() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		_apply_key(action, DEFAULT_KEYS[action])
	_save_bindings()
	bindings_changed.emit()


func _register_actions() -> void:
	if not InputMap.has_action(ACTION_CANCEL):
		InputMap.add_action(ACTION_CANCEL)
	InputMap.action_erase_events(ACTION_CANCEL)
	InputMap.action_add_event(ACTION_CANCEL, _make_key_event(KEY_ESCAPE))

	for action: StringName in REBINDABLE_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_apply_key(action, DEFAULT_KEYS[action])


func _apply_key(action: StringName, keycode: Key) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, _make_key_event(keycode))


func _make_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event


func _load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(_save_path) != OK:
		return
	for action: StringName in REBINDABLE_ACTIONS:
		var keycode: int = config.get_value(SECTION_KEYS, String(action), DEFAULT_KEYS[action])
		if keycode != KEY_ESCAPE and keycode != KEY_NONE:
			_apply_key(action, keycode as Key)


func _save_bindings() -> void:
	var config := ConfigFile.new()
	for action: StringName in REBINDABLE_ACTIONS:
		config.set_value(SECTION_KEYS, String(action), get_keycode(action))
	config.save(_save_path)
