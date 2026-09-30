class_name InputBindings
extends Node

## Rebindable keyboard shortcuts. Registers the actions in InputMap at runtime (the
## project settings stay untouched), applies saved rebindings and turns unhandled
## presses into signals. The project fills in the action table in its wiring subclass.

## The fixed cancel key was pressed. It is never rebindable, so nobody gets locked out.
signal cancel_pressed
## A rebindable action outside `direct_actions` was pressed.
signal shortcut_pressed(action: StringName)
signal bindings_changed

const CANCEL_KEY: Key = KEY_ESCAPE
const SECTION_KEYS: String = "keys"

var cancel_action: StringName = &"menu_cancel"
## Shown in this order by KeyBindingsTab.
var rebindable_actions: Array[StringName] = []
## Actions whose listener reads them in its own _input(), so no shortcut_pressed.
var direct_actions: Array[StringName] = []
var default_keys: Dictionary = {}   # action -> Key
var action_labels: Dictionary = {}  # action -> player-facing name
## Wording for KeyBindingsTab: "hint", "press_key", "key_in_use" (with %s), "reset".
var ui_text: Dictionary = {
	"hint": "Pick an action and press a new key. Esc cancels.",
	"press_key": "Press a key...",
	"key_in_use": "Key already in use: %s",
	"reset": "Reset to defaults",
}
## Its own file: a settings store that rewrites its file from memory would drop this section.
var save_path: String = "user://input_bindings.cfg"


func _ready() -> void:
	register_actions()
	load_bindings()


## The cancel key is checked first so it always wins.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(cancel_action):
		cancel_pressed.emit()
		get_viewport().set_input_as_handled()
		return

	for action: StringName in rebindable_actions:
		if direct_actions.has(action):
			continue
		if event.is_action_pressed(action):
			shortcut_pressed.emit(action)
			get_viewport().set_input_as_handled()
			return


func get_action_label(action: StringName) -> String:
	return action_labels.get(action, String(action))


## The key bound to `action`, as text for buttons and hints.
func get_binding_text(action: StringName) -> String:
	var keycode: Key = get_keycode(action)
	return OS.get_keycode_string(keycode) if keycode != KEY_NONE else ""


func get_keycode(action: StringName) -> Key:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).keycode
	return KEY_NONE


## Binds `keycode` to `action` and saves. Returns the action that already uses that
## key (nothing changes then), or &"" on success. The cancel key is reserved.
func rebind(action: StringName, keycode: Key) -> StringName:
	if keycode == CANCEL_KEY:
		return cancel_action
	for other: StringName in rebindable_actions:
		if other != action and get_keycode(other) == keycode:
			return other

	_apply_key(action, keycode)
	save_bindings()
	bindings_changed.emit()
	return &""


func reset_to_defaults() -> void:
	for action: StringName in rebindable_actions:
		_apply_key(action, default_keys[action])
	save_bindings()
	bindings_changed.emit()


func register_actions() -> void:
	if not InputMap.has_action(cancel_action):
		InputMap.add_action(cancel_action)
	_apply_key(cancel_action, CANCEL_KEY)

	for action: StringName in rebindable_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_apply_key(action, default_keys[action])


func load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	for action: StringName in rebindable_actions:
		var keycode: int = config.get_value(SECTION_KEYS, String(action), default_keys[action])
		if keycode != CANCEL_KEY and keycode != KEY_NONE:
			_apply_key(action, keycode as Key)


func save_bindings() -> void:
	var config := ConfigFile.new()
	for action: StringName in rebindable_actions:
		config.set_value(SECTION_KEYS, String(action), get_keycode(action))
	config.save(save_path)


func _apply_key(action: StringName, keycode: Key) -> void:
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)
