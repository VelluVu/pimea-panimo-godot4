class_name KeyBindingsTab
extends VBoxContainer

## The options window's Input tab. Built from InputManager's action list, so a new
## rebindable action shows up without touching the scene.

const RESET_BINDINGS_TEXT : String = "Palauta oletukset"
const PRESS_KEY_TEXT : String = "Paina näppäintä..."
const INPUT_HINT_TEXT : String = "Valitse toiminto ja paina uutta näppäintä. Esc peruu."
const KEY_IN_USE_FORMAT : String = "Näppäin on jo käytössä: %s"
const BINDING_BUTTON_MIN_WIDTH : float = 110.0

var _binding_buttons : Dictionary = {} # action -> Button
var _capturing_action : StringName = &""
var _status_label : Label


func _ready() -> void:
	_add_wrapping_label(INPUT_HINT_TEXT)
	_add_binding_rows()
	_status_label = _add_wrapping_label("")

	var reset_button := Button.new()
	reset_button.text = RESET_BINDINGS_TEXT
	reset_button.pressed.connect(_on_reset_pressed)
	add_child(reset_button)

	InputManager.bindings_changed.connect(_refresh_buttons)
	_refresh_buttons()


func cancel_capture() -> void:
	_capturing_action = &""
	_refresh_buttons()


## Takes a key press while a binding is waiting for one. Returns true if it was consumed.
func try_capture(event : InputEvent) -> bool:
	if _capturing_action == &"" or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	_finish_capture(key_event.keycode)
	return true


func _add_wrapping_label(text : String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label


func _add_binding_rows() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	for action : StringName in InputManager.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		rows.add_child(row)

		var name_label := Label.new()
		name_label.text = InputManager.get_action_label(action)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var key_button := Button.new()
		key_button.custom_minimum_size.x = BINDING_BUTTON_MIN_WIDTH
		key_button.pressed.connect(_on_binding_pressed.bind(action))
		row.add_child(key_button)
		_binding_buttons[action] = key_button


func _refresh_buttons() -> void:
	for action : StringName in _binding_buttons:
		var key_button : Button = _binding_buttons[action]
		key_button.text = PRESS_KEY_TEXT if action == _capturing_action else InputManager.get_binding_text(action)


func _on_binding_pressed(action : StringName) -> void:
	_capturing_action = action
	_status_label.text = ""
	_refresh_buttons()


## Esc cancels; any other key is offered to InputManager, which refuses keys already
## bound to another action.
func _finish_capture(keycode : Key) -> void:
	var action : StringName = _capturing_action
	_capturing_action = &""
	_status_label.text = ""
	if keycode != KEY_ESCAPE:
		var conflict : StringName = InputManager.rebind(action, keycode)
		if conflict != &"":
			_status_label.text = KEY_IN_USE_FORMAT % InputManager.get_action_label(conflict)
	_refresh_buttons()


func _on_reset_pressed() -> void:
	_capturing_action = &""
	_status_label.text = ""
	InputManager.reset_to_defaults()
