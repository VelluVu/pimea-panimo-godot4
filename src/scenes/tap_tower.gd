class_name TapTower
extends Node2D

## The tap tower on the bar counter: one tap per keg the brewery owns, on a crossbar that
## widens with them (TapLayout). Batches on serve take the taps from the left, each handle
## tinted with its beer's colour; spare taps stay grey. Drawn from the tap art's parts.

const BAR_LEFT : Texture2D = preload("res://assets/textures/tap/tap_bar_left.png")
const BAR_SEGMENT : Texture2D = preload("res://assets/textures/tap/tap_bar_segment.png")
const BAR_RIGHT : Texture2D = preload("res://assets/textures/tap/tap_bar_right.png")
const HANDLE : Texture2D = preload("res://assets/textures/tap/tap_handle.png")
const SPOUT : Texture2D = preload("res://assets/textures/tap/tap_spout.png")
const STEM : Texture2D = preload("res://assets/textures/tap/tap_stem.png")
const TRAY_LEFT : Texture2D = preload("res://assets/textures/tap/tap_tray_left.png")
const TRAY_MIDDLE : Texture2D = preload("res://assets/textures/tap/tap_tray_middle.png")
const TRAY_RIGHT : Texture2D = preload("res://assets/textures/tap/tap_tray_right.png")

## Rows of the old 48 px sprite, which was centred on this node.
const HANDLE_TOP : int = 4 - 24
const BAR_CAP_TOP : int = 12 - 24
const BAR_TOP : int = 13 - 24
const SPOUT_TOP : int = 19 - 24
const STEM_TOP : int = 19 - 24
const TRAY_TOP : int = 41 - 24
## An unused tap's handle.
const IDLE_HANDLE_COLOR : Color = Color("8b9bb4")

var _taps : int = 1
var _colors : Array[Color] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## `kegs` owned, and one colour per batch on serve in tap order.
func set_taps(kegs : int, colors : Array[Color]) -> void:
	_taps = TapLayout.tap_count(kegs)
	_colors = colors.slice(0, _taps)
	queue_redraw()


func tap_count() -> int:
	return _taps


## Global x of tap `index`'s spout.
func spout_global_x(index : int) -> float:
	return to_global(Vector2(TapLayout.spout_x(tap_count(), index), 0.0)).x


func _draw() -> void:
	var taps : int = tap_count()
	_draw_tray(taps)
	draw_texture(STEM, Vector2(-STEM.get_width() / 2.0, STEM_TOP))
	_draw_bar(taps)
	for i : int in taps:
		var left : float = TapLayout.handle_left(taps, i)
		var color : Color = _colors[i] if i < _colors.size() else IDLE_HANDLE_COLOR
		draw_texture(HANDLE, Vector2(left, HANDLE_TOP), color)
		draw_texture(SPOUT, Vector2(left + 1, SPOUT_TOP))


func _draw_bar(taps : int) -> void:
	var left : float = TapLayout.bar_left(taps)
	var right : float = left + TapLayout.bar_width(taps) - TapLayout.CAP_WIDTH
	draw_texture(BAR_LEFT, Vector2(left, BAR_CAP_TOP))
	var x : float = left + TapLayout.CAP_WIDTH
	while x < right:
		var width : float = minf(BAR_SEGMENT.get_width(), right - x)
		draw_texture_rect_region(BAR_SEGMENT, Rect2(x, BAR_TOP, width, BAR_SEGMENT.get_height()), Rect2(0, 0, width, BAR_SEGMENT.get_height()))
		x += width
	draw_texture(BAR_RIGHT, Vector2(right, BAR_CAP_TOP))


func _draw_tray(taps : int) -> void:
	var left : float = -TapLayout.tray_width(taps) / 2.0
	var right : float = left + TapLayout.tray_width(taps) - TRAY_RIGHT.get_width()
	draw_texture(TRAY_LEFT, Vector2(left, TRAY_TOP))
	var x : float = left + TRAY_LEFT.get_width()
	while x < right:
		var width : float = minf(TRAY_MIDDLE.get_width(), right - x)
		draw_texture_rect_region(TRAY_MIDDLE, Rect2(x, TRAY_TOP, width, TRAY_MIDDLE.get_height()), Rect2(0, 0, width, TRAY_MIDDLE.get_height()))
		x += width
	draw_texture(TRAY_RIGHT, Vector2(right, TRAY_TOP))
