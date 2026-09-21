@tool
extends McpTestSuite

## Unit tests for CollapsibleSection: header rewrap and the toggle state.

const CollapsibleSectionScript := preload("res://src/ui/collapsible_section.gd")


func suite_name() -> String:
	return "collapsible_section"


func _make_container() -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_child(Label.new())
	container.add_child(Label.new())
	container.add_child(Label.new())
	return container


func test_header_row_takes_the_labels_place() -> void:
	var container := _make_container()
	var header : Label = container.get_child(1)
	CollapsibleSectionScript.new(container, header)
	assert_eq(container.get_child_count(), 3)
	assert_eq(header.get_parent(), container.get_child(1), "label now sits in the row at its old index")
	container.free()


func test_pressing_the_button_toggles_and_emits() -> void:
	var container := _make_container()
	var header : Label = container.get_child(0)
	var section = CollapsibleSectionScript.new(container, header)
	var button : Button = header.get_parent().get_child(1)
	var emitted : Array = []
	section.toggled.connect(func(collapsed : bool) -> void: emitted.append(collapsed))

	button.pressed.emit()
	assert_true(section.collapsed)
	assert_eq(button.text, CollapsibleSectionScript.EXPAND_ICON)
	button.pressed.emit()
	assert_false(section.collapsed)
	assert_eq(button.text, CollapsibleSectionScript.COLLAPSE_ICON)
	assert_eq(emitted, [true, false])
	container.free()
