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

## Asked for the window that holds the keyboard; outside it the game's own keys rule.
var top_window : Callable

var _idle_seconds : float = 0.0
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
	if focused == null or focused.has_focus(true) or not _in_top_window(focused):
		return
	for action : StringName in NAVIGATION_ACTIONS:
		if event.is_action_pressed(action, true):
			focused.grab_focus()
			get_viewport().set_input_as_handled()
			return


func _process(delta : float) -> void:
	var focused : Control = get_viewport().gui_get_focus_owner()
	if focused != null and focused.has_focus(true):
		_idle_seconds += delta
		if _idle_seconds >= HIDE_AFTER_SECONDS:
			focused.grab_focus(true)
	_place_frame(focused)


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


func _in_top_window(control : Control) -> bool:
	var window : Control = top_window.call() if top_window.is_valid() else null
	return window != null and window.is_ancestor_of(control)
