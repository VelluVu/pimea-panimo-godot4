class_name KeyBindingsTab
extends VBoxContainer

## A settings tab that lists every rebindable action with its key. Built from the
## InputBindings passed to setup(), so a new action shows up without touching a scene.
## The owner forwards key presses to try_capture() from its _input().

const BINDING_BUTTON_MIN_WIDTH : float = 110.0

var _binding_buttons : Dictionary = {} # action -> Button
var _capturing_action : StringName = &""
var _status_label : Label
var _bindings : InputBindings


## Call before adding the tab to the tree.
func setup(bindings : InputBindings) -> void:
	_bindings = bindings


func _ready() -> void:
	_add_wrapping_label(_bindings.ui_text["hint"])
	_add_binding_rows()
	_status_label = _add_wrapping_label("")

	var reset_button := Button.new()
	reset_button.text = _bindings.ui_text["reset"]
	reset_button.pressed.connect(_on_reset_pressed)
	add_child(reset_button)

	_bindings.bindings_changed.connect(_refresh_buttons)
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

	for action : StringName in _bindings.rebindable_actions:
		var row := HBoxContainer.new()
		rows.add_child(row)

		var name_label := Label.new()
		name_label.text = _bindings.get_action_label(action)
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
		key_button.text = _bindings.ui_text["press_key"] if action == _capturing_action else _bindings.get_binding_text(action)


func _on_binding_pressed(action : StringName) -> void:
	_capturing_action = action
	_status_label.text = ""
	_refresh_buttons()


## Esc cancels; any other key is offered to the bindings, which refuse keys already
## bound to another action.
func _finish_capture(keycode : Key) -> void:
	var action : StringName = _capturing_action
	_capturing_action = &""
	_status_label.text = ""
	if keycode != KEY_ESCAPE:
		var conflict : StringName = _bindings.rebind(action, keycode)
		if conflict != &"":
			_status_label.text = _bindings.ui_text["key_in_use"] % _bindings.get_action_label(conflict)
	_refresh_buttons()


func _on_reset_pressed() -> void:
	_capturing_action = &""
	_status_label.text = ""
	_bindings.reset_to_defaults()
