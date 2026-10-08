class_name PortraitNotice
extends CanvasLayer

## The game is built for landscape. On a touch screen held upright this covers the screen,
## asks the player to turn the phone and holds the pause until they do. Add one to each
## scene's UI root.

## Above every window, the level-up cards and touch tooltips.
const LAYER : int = 127
const NOTICE_TEXT : String = "Käännä puhelin vaakatasoon."
const BACKGROUND_COLOR : Color = Color(0.03, 0.02, 0.04, 1)
const TEXT_COLOR : Color = Color(0.949, 0.788, 0.42, 1)
## Four times the pixel font's size: sharp, and readable on an upright phone.
const FONT_SIZE : int = 64
const TEXT_MARGIN : float = 16.0

var _cover : ColorRect


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not DisplayServer.is_touchscreen_available():
		return
	_cover = ColorRect.new()
	_cover.color = BACKGROUND_COLOR
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Swallows taps, so nothing behind it is pressed while the phone is upright.
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.add_child(_make_label())
	_cover.theme = _borrowed_theme()
	_cover.hide()
	add_child(_cover)
	PauseLock.hold_while_visible(_cover)
	_refresh()


## Checked every frame: the web build turning the phone did not emit size_changed.
func _process(_delta : float) -> void:
	if _cover != null:
		_refresh()


static func is_portrait(window_size : Vector2i) -> bool:
	return window_size.y > window_size.x


func _refresh() -> void:
	var portrait : bool = is_portrait(DisplayServer.window_get_size())
	if _cover.visible != portrait:
		_cover.visible = portrait


## This layer sits outside the UI's theme, so the notice borrows the nearest one above it.
func _borrowed_theme() -> Theme:
	var node : Node = get_parent()
	while node != null:
		if node is Control and (node as Control).theme != null:
			return (node as Control).theme
		node = node.get_parent()
	return ThemeDB.get_project_theme()


func _make_label() -> Label:
	var label := Label.new()
	label.text = NOTICE_TEXT
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = TEXT_MARGIN
	label.offset_right = -TEXT_MARGIN
	return label
