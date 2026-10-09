class_name PortraitNotice
extends CanvasLayer

## The game is built for landscape. On a touch screen held upright this covers the screen,
## asks the player to turn the phone and holds the pause until they do. With the phone's
## rotation lock on, turning does nothing, so a tap asks the browser for a fullscreen
## landscape instead (Android; iOS has no orientation lock). Add one to each scene's UI root.

## Above every window, the level-up cards and touch tooltips.
const LAYER : int = 127
const NOTICE_TEXT : String = "Käännä puhelin vaakatasoon."
const LOCK_HINT_TEXT : String = "Kierto lukossa? Kosketa ruutua tai salli näytön kierto."
const BACKGROUND_COLOR : Color = Color(0.03, 0.02, 0.04, 1)
const TEXT_COLOR : Color = Color(0.949, 0.788, 0.42, 1)
## Four times the pixel font's size: sharp, and readable on an upright phone.
const FONT_SIZE : int = 64
const HINT_FONT_SIZE : int = 32
const HINT_COLOR : Color = Color(0.75, 0.68, 0.55, 1)
## The lock only works in fullscreen, and both need the tap's user activation.
const LANDSCAPE_JS : String = """
(async () => {
	try {
		if (!document.fullscreenElement) { await document.documentElement.requestFullscreen(); }
		await screen.orientation.lock('landscape');
	} catch (e) {}
})();
"""
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
	_cover.add_child(_make_texts())
	_cover.gui_input.connect(_on_cover_input)
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


## On the release: a browser counts only the end of a touch as the user's permission.
func _on_cover_input(event : InputEvent) -> void:
	var tapped : bool = (event is InputEventScreenTouch or event is InputEventMouseButton) 			and event.is_released()
	if tapped and OS.has_feature("web"):
		JavaScriptBridge.eval(LANDSCAPE_JS)


func _make_texts() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = TEXT_MARGIN
	box.offset_right = -TEXT_MARGIN
	box.add_child(_make_label(NOTICE_TEXT, FONT_SIZE, TEXT_COLOR))
	box.add_child(_make_label(LOCK_HINT_TEXT, HINT_FONT_SIZE, HINT_COLOR))
	return box


func _make_label(text : String, font_size : int, color : Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
