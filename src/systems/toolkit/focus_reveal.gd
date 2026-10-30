class_name FocusReveal
extends Node

## The keyboard focus frame of FirstFocus windows: it fades after a few seconds without
## keyboard use, and the first navigation key after that only shows it again where it was,
## so the player sees where they are before anything moves or gets pressed. It also draws
## the frame around a focused slider, which has none. FirstFocus adds one to the viewport.

const HIDE_AFTER_SECONDS : float = 3.0
const NAVIGATION_ACTIONS : Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev", &"ui_accept"]
## A slider draws no focus style of its own, so this one is drawn around it: the theme's
## button focus frame, this much bigger than the thin slider.
const FRAME_STYLE : StringName = &"focus"
const FRAME_STYLE_TYPE : StringName = &"Button"
const FRAME_GROW : float = 3.0
const FRAME_LAYER : int = 100
## Pixels a key press scrolls a list that has nothing to focus; held keys repeat.
const SCROLL_STEP : int = 32

## Asked for the window that holds the keyboard; outside it the game's own keys rule.
var top_window : Callable

var _idle_seconds : float = 0.0
## The focus last seen inside the top window, to notice when its control disappears.
var _tracking : bool = false
var _last_focused : Control
var _last_window : Control
var _last_shown : bool = false
var _frame : Control
var _frame_style : StyleBox


func _ready() -> void:
	# Menus pause the tree, and they are where the focus matters most.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = FRAME_LAYER
	add_child(layer)
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.visible = false
	_frame.draw.connect(func() -> void:
		if _frame_style != null:
			_frame.draw_style_box(_frame_style, Rect2(Vector2.ZERO, _frame.size)))
	layer.add_child(_frame)


func _input(event : InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if not event.is_pressed():
		return
	_idle_seconds = 0.0
	var focused : Control = get_viewport().gui_get_focus_owner()
	if focused == null or not _in_top_window(focused):
		_scroll_unfocusable(event)
		return
	if focused.has_focus(true):
		return
	for action : StringName in NAVIGATION_ACTIONS:
		if event.is_action_pressed(action, true):
			focused.grab_focus()
			get_viewport().set_input_as_handled()
			return


func _process(delta : float) -> void:
	var focused : Control = get_viewport().gui_get_focus_owner()
	_keep_focus_in_window(focused)
	focused = get_viewport().gui_get_focus_owner()
	if focused != null and focused.has_focus(true):
		_idle_seconds += delta
		if _idle_seconds >= HIDE_AFTER_SECONDS:
			focused.grab_focus(true)
	_place_frame(focused)


## A window that swaps its content in place (a confirmation replacing the menu buttons)
## hides the focused button, and Godot drops the focus. The window's preferred or first
## control takes it, shown if it was. A control that lets go on purpose but stays in
## sight, such as a key binding waiting for its key, is left alone.
func _keep_focus_in_window(focused : Control) -> void:
	var window : Control = top_window.call() if top_window.is_valid() else null
	if focused != null:
		_tracking = window != null and window.is_ancestor_of(focused)
		_last_focused = focused if _tracking else null
		_last_window = window if _tracking else null
		_last_shown = focused.has_focus(true)
		return
	# A flag, not a null check: a freed control also compares equal to null.
	if not _tracking:
		return
	var lost : bool = not is_instance_valid(_last_focused) or not _last_focused.is_visible_in_tree()
	var same_window : bool = window != null and window == _last_window and window.is_visible_in_tree()
	if lost and same_window:
		FirstFocus.focus_now(window, not _last_shown)
	if lost or not same_window:
		_tracking = false


func _place_frame(focused : Control) -> void:
	var shown : bool = focused != null and focused is Slider and focused.has_focus(true) and focused.is_visible_in_tree()
	_frame.visible = shown
	if not shown:
		return
	_frame_style = focused.get_theme_stylebox(FRAME_STYLE, FRAME_STYLE_TYPE)
	# Screen coordinates, so the frame's own layer lines up with any canvas layer.
	var screen : Transform2D = focused.get_global_transform_with_canvas()
	var rect := Rect2(screen.origin, focused.size * screen.get_scale()).grow(FRAME_GROW)
	if rect != Rect2(_frame.position, _frame.size):
		_frame.position = rect.position
		_frame.size = rect.size
		_frame.queue_redraw()


## A window with nothing to focus, such as a list of achievements, still scrolls with the
## up and down keys.
func _scroll_unfocusable(event : InputEvent) -> void:
	var window : Control = top_window.call() if top_window.is_valid() else null
	if window == null:
		return
	var direction : int = 0
	if event.is_action_pressed(&"ui_down", true):
		direction = 1
	elif event.is_action_pressed(&"ui_up", true):
		direction = -1
	if direction == 0:
		return
	var scroll : ScrollContainer = _scroll_list(window)
	if scroll != null:
		scroll.scroll_vertical += direction * SCROLL_STEP
		get_viewport().set_input_as_handled()


## The first scroll list in the window that has more than fits.
func _scroll_list(node : Node) -> ScrollContainer:
	for child : Node in node.get_children():
		var scroll : ScrollContainer = child as ScrollContainer
		if scroll != null and scroll.is_visible_in_tree() and scroll.get_v_scroll_bar().max_value > scroll.size.y:
			return scroll
		var found : ScrollContainer = _scroll_list(child)
		if found != null:
			return found
	return null


func _in_top_window(control : Control) -> bool:
	var window : Control = top_window.call() if top_window.is_valid() else null
	return window != null and window.is_ancestor_of(control)
