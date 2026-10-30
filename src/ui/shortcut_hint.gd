class_name ShortcutHint
extends RefCounted

## Adds a spot's keyboard shortcut to its hover label: "Panimo (P)". Follows rebinding, and
## stays off touch screens, where there is no key to press.

const HINT_FORMAT : String = "%s (%s)"


## `key` empty (an unbound action) leaves the name alone.
static func text(name : String, key : String) -> String:
	return name if key.is_empty() else HINT_FORMAT % [name, key]


## `label` keeps its current text as the Finnish name.
static func attach(label : Label, action : StringName) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	var name : String = label.text
	# The joined text is no translation key; the name is translated before joining.
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var refresh : Callable = func() -> void:
		label.text = text(UiText.of(name), InputManager.get_binding_text(action))
	InputManager.bindings_changed.connect(refresh)
	# The autoload outlives the GUI, so the label lets go when it leaves.
	label.tree_exiting.connect(func() -> void: InputManager.bindings_changed.disconnect(refresh), CONNECT_ONE_SHOT)
	refresh.call()
