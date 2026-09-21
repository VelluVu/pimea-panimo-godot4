class_name DevConsole
extends Panel

## A collapsible, resizable console panel: a running log and a command line. Independent of
## any game: feed it with log_line(), give it commands through `registry`, and set
## `open_action` and `cancel_action` (InputMap actions). Everything project-specific lives in
## ConsoleWiring, which this adds as a child.

const COLLAPSE_ICON: String = "▼"
const EXPAND_ICON: String = "▲"
const MAX_LOG_LINES: int = 200

const MIN_SIZE: Vector2 = Vector2(180, 90)
## Capped so the console cannot cover whatever shares its corner (its mouse_filter is STOP).
const MAX_SIZE: Vector2 = Vector2(440, 200)

const FOCUS_STYLE_BORDER_COLOR: Color = Color(0.85, 0.65, 0.25)

@onready var resize_handle: Control = $ResizeHandle
@onready var toggle_button: Button = $MarginContainer/MainVBox/HeaderHBox/ToggleButton
@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var body_vbox: VBoxContainer = $MarginContainer/MainVBox/BodyVBox
@onready var log_scroll: ScrollContainer = $MarginContainer/MainVBox/BodyVBox/LogScroll
@onready var log_label: RichTextLabel = $MarginContainer/MainVBox/BodyVBox/LogScroll/LogLabel
@onready var input_line_edit: LineEdit = $MarginContainer/MainVBox/BodyVBox/InputLineEdit

## The dispatch table. Register commands on it, or add a ConsoleCommandSet.
var registry: ConsoleCommandRegistry
## InputMap actions: one opens and focuses the console, the other closes it. Empty = unused.
var open_action: StringName = &""
var cancel_action: StringName = &""

var _is_collapsed: bool = true
var _expanded_size: Vector2

var _is_resizing: bool = false
var _resize_start_mouse: Vector2
var _resize_start_offset_left: float
var _resize_start_offset_top: float

var _log_lines: PackedStringArray = []


func _ready() -> void:
	_expanded_size = size

	toggle_button.pressed.connect(_on_toggle_pressed)
	input_line_edit.text_submitted.connect(_on_command_submitted)
	input_line_edit.focus_entered.connect(_apply_focus_style.bind(true))
	input_line_edit.focus_exited.connect(_apply_focus_style.bind(false))
	resize_handle.gui_input.connect(_on_resize_handle_gui_input)

	registry = ConsoleCommandRegistry.new(log_line)
	var wiring := ConsoleWiring.new()
	wiring.name = "ConsoleWiring"
	add_child(wiring)
	# Registered after the wiring's sets, so `help` lists the project's commands first.
	registry.register("clear", _cmd_clear)
	registry.register("help", registry.print_help, "", "", false, false)

	_apply_focus_style(false)
	_apply_collapsed_state()


## Deliberately _input(), not _unhandled_input(): it re-reads the field's focus on every
## keypress. The open key opens/focuses the console, or types normally while the field has
## focus. The cancel key closes it before anything else can treat it as a cancel.
func _input(event: InputEvent) -> void:
	if open_action != &"" and event.is_action_pressed(open_action):
		if input_line_edit.has_focus():
			return
		_open_and_focus_input()
		get_viewport().set_input_as_handled()
		return

	if cancel_action != &"" and event.is_action_pressed(cancel_action) and is_console_active():
		input_line_edit.release_focus()
		if not _is_collapsed:
			_on_toggle_pressed()
		get_viewport().set_input_as_handled()


## True while the console is open or focused, so the host's own shortcuts can back off.
func is_console_active() -> bool:
	return not _is_collapsed or input_line_edit.has_focus()


## Appends one BBCode line to the log.
func log_line(bbcode_line: String) -> void:
	log_label.append_text(bbcode_line + "\n")
	_log_lines.append(bbcode_line)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)
		log_label.clear()
		log_label.append_text("\n".join(_log_lines) + "\n")
	_scroll_log_to_bottom()


func _open_and_focus_input() -> void:
	if _is_collapsed:
		_on_toggle_pressed()
	input_line_edit.grab_focus()


func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	_apply_collapsed_state()


func _apply_collapsed_state() -> void:
	if _is_collapsed:
		_expanded_size = size
		body_vbox.hide()
		toggle_button.text = EXPAND_ICON
		offset_top = offset_bottom - _header_height()
	else:
		body_vbox.show()
		toggle_button.text = COLLAPSE_ICON
		offset_top = offset_bottom - _expanded_size.y


func _header_height() -> float:
	return $MarginContainer/MainVBox/HeaderHBox.size.y + 10.0


## Drag-resize from the top-left corner; the bottom-right corner stays anchored.
func _on_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_resizing = true
			_resize_start_mouse = get_global_mouse_position()
			_resize_start_offset_left = offset_left
			_resize_start_offset_top = offset_top
		else:
			_is_resizing = false
	elif event is InputEventMouseMotion and _is_resizing:
		var delta := get_global_mouse_position() - _resize_start_mouse
		var new_width: float = clampf(-(_resize_start_offset_left + delta.x) + offset_right, MIN_SIZE.x, MAX_SIZE.x)
		var new_height: float = clampf(-(_resize_start_offset_top + delta.y) + offset_bottom, MIN_SIZE.y, MAX_SIZE.y)
		offset_left = offset_right - new_width
		if not _is_collapsed:
			offset_top = offset_bottom - new_height
			_expanded_size = Vector2(new_width, new_height)
		else:
			_expanded_size.x = new_width


func _apply_focus_style(is_focused: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	box.set_border_width_all(2 if is_focused else 1)
	box.border_color = FOCUS_STYLE_BORDER_COLOR if is_focused else Color(0.3, 0.3, 0.3)
	box.set_corner_radius_all(3)
	input_line_edit.add_theme_stylebox_override("normal", box)
	input_line_edit.add_theme_stylebox_override("focus", box)


## LogScroll does the scrolling (LogLabel just fits its content). Its max_value only
## updates after layout, so wait a frame before snapping to the bottom.
func _scroll_log_to_bottom() -> void:
	await get_tree().process_frame
	log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


## LineEdit drops focus on Enter, so grab it back to keep the input ready.
func _on_command_submitted(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	input_line_edit.clear()
	input_line_edit.grab_focus()
	if text.is_empty():
		return

	log_line("[color=gray]> %s[/color]" % text)
	registry.execute(text)


func _cmd_clear(_args: PackedStringArray) -> void:
	log_label.clear()
	_log_lines.clear()
