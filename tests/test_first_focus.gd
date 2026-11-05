@tool
extends McpTestSuite

var _window : Control = null


func suite_name() -> String:
	return "first_focus"


func setup() -> void:
	_window = Control.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_window)


func teardown() -> void:
	_window.queue_free()
	_window = null


func _button(parent : Node) -> Button:
	var button := Button.new()
	parent.add_child(button)
	return button


func test_focuses_first_button() -> void:
	var first : Button = _button(_window)
	_button(_window)
	FirstFocus.focus_now(_window)
	assert_true(first.has_focus())


func test_preferred_button_wins() -> void:
	_button(_window)
	var safe : Button = _button(_window)
	FirstFocus.prefer(safe)
	FirstFocus.focus_now(_window)
	assert_true(safe.has_focus())


func test_skips_button_under_disabled_focus_behavior() -> void:
	var shut := Control.new()
	shut.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_window.add_child(shut)
	var hidden_from_keys : Button = _button(shut)
	var open : Button = _button(_window)
	FirstFocus.focus_now(_window)
	assert_false(hidden_from_keys.has_focus())
	assert_true(open.has_focus())


func test_skips_disabled_button() -> void:
	var disabled : Button = _button(_window)
	disabled.disabled = true
	var enabled : Button = _button(_window)
	FirstFocus.focus_now(_window)
	assert_true(enabled.has_focus())
