class_name CollapsibleSection
extends RefCounted

## Puts a small arrow button beside a header label, at the label's place in its
## container. The owner reads `collapsed` and shows or hides the section's lines.

signal toggled(collapsed : bool)

const COLLAPSE_ICON : String = "▼"
const EXPAND_ICON : String = "▲"
const BUTTON_SIZE : Vector2 = Vector2(16, 12)
const BUTTON_FONT_SIZE : int = 10

var collapsed : bool = false

var _button : Button


static func icon_for(is_collapsed : bool) -> String:
	return EXPAND_ICON if is_collapsed else COLLAPSE_ICON


## Reparents `header_label` into a new row with the button and puts the row back at
## the label's original index in `container`.
func _init(container : Container, header_label : Label) -> void:
	var original_index : int = header_label.get_index()

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	container.remove_child(header_label)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(header_label)

	_button = Button.new()
	_button.custom_minimum_size = BUTTON_SIZE
	_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_button.flat = true
	_button.text = icon_for(collapsed)
	_button.pressed.connect(_on_pressed)
	row.add_child(_button)

	container.add_child(row)
	container.move_child(row, original_index)


func _on_pressed() -> void:
	collapsed = not collapsed
	_button.text = icon_for(collapsed)
	toggled.emit(collapsed)
