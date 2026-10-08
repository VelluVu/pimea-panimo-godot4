class_name OptionStepper
extends RefCounted

## Puts < and > buttons around an OptionButton, so the next or previous item is one tap
## away without opening the list. Skips disabled items, wraps around at the ends, and emits
## item_selected like a pick from the list would.
##   OptionStepper.wrap(my_option_button)

const BUTTON_SIZE: Vector2 = Vector2(26, 26)
const PREVIOUS_TEXT: String = "<"
const NEXT_TEXT: String = ">"


## Moves `option` into a new row [<] option [>] at its place and returns the row.
static func wrap(option: OptionButton) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var parent: Node = option.get_parent()
	var index: int = option.get_index()
	parent.remove_child(option)
	parent.add_child(row)
	parent.move_child(row, index)

	row.add_child(_make_button(option, PREVIOUS_TEXT, -1))
	row.add_child(option)
	row.add_child(_make_button(option, NEXT_TEXT, 1))
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


## The next enabled index from `current` in `direction` (1 or -1), wrapping around, or
## `current` when no other item is enabled.
static func next_index(current: int, direction: int, disabled: Array[bool]) -> int:
	var count: int = disabled.size()
	for step: int in range(1, count + 1):
		var candidate: int = posmod(current + direction * step, count)
		if not disabled[candidate]:
			return candidate
	return current


static func _make_button(option: OptionButton, text: String, direction: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(func() -> void:
		if option.item_count == 0:
			return
		var disabled: Array[bool] = []
		for i: int in option.item_count:
			disabled.append(option.is_item_disabled(i))
		var target: int = next_index(option.selected, direction, disabled)
		if target != option.selected:
			option.select(target)
			option.item_selected.emit(target))
	return button
