class_name TapTower
extends Node2D

## One tap per keg on a crossbar that widens with them (TapLayout); batches on serve take
## taps from the left with tinted handles, spares stay grey. Built from three pictures, each
## with a 1 px empty frame.

const UNIT : Texture2D = preload("res://assets/textures/tap/tap_unit.png")
const END : Texture2D = preload("res://assets/textures/tap/tap_end.png")
const BASE : Texture2D = preload("res://assets/textures/tap/tap_base.png")

## Every picture has an empty 1 px frame; only the art inside counts.
const PART_PADDING : int = 1
## The handle's corner and size inside tap_unit.png's art, the part that gets tinted.
const HANDLE_SIZE : Vector2 = Vector2(5, 9)
## Rows of tap_base.png's art: the column and its foot, then the tray.
const COLUMN_HEIGHT : int = 22
const TRAY_HEIGHT : int = 6
## Rows of the old 48 px sprite, which was centred on this node.
const UNIT_TOP : int = 4 - 24
const END_TOP : int = 12 - 24
const BASE_TOP : int = 19 - 24
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
	_draw_region(BASE, Rect2(-floorf(_size(BASE).x / 2.0), BASE_TOP, _size(BASE).x, COLUMN_HEIGHT), Vector2.ZERO)
	_draw_tray(taps)
	var left : float = TapLayout.bar_left(taps)
	var right_end : float = left + TapLayout.bar_width(taps) - TapLayout.CAP_WIDTH
	for i : int in taps:
		# Taps closer than a whole picture overlap; the last one stops at the right end.
		var x : float = TapLayout.handle_left(taps, i)
		var width : float = minf(_size(UNIT).x, right_end - x)
		_draw_region(UNIT, Rect2(x, UNIT_TOP, width, _size(UNIT).y), Vector2.ZERO)
		var color : Color = _colors[i] if i < _colors.size() else IDLE_HANDLE_COLOR
		_draw_region(UNIT, Rect2(Vector2(x, UNIT_TOP), HANDLE_SIZE), Vector2.ZERO, color)
	_draw_part(END, Vector2(left, END_TOP))
	# The right end is the left one mirrored, so both ends match.
	draw_set_transform(Vector2(right_end + _size(END).x, 0.0), 0.0, Vector2(-1.0, 1.0))
	_draw_part(END, Vector2(0.0, END_TOP))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The tray's pattern repeated to TapLayout.tray_width(), the last copy cut to fit.
func _draw_tray(taps : int) -> void:
	var width : int = TapLayout.tray_width(taps)
	@warning_ignore("integer_division")
	var x : float = -(width / 2)
	var end : float = x + width
	while x < end:
		var piece : float = minf(TapLayout.TRAY_PATTERN, end - x)
		_draw_region(BASE, Rect2(x, BASE_TOP + COLUMN_HEIGHT, piece, TRAY_HEIGHT), Vector2(0, COLUMN_HEIGHT))
		x += piece


## The art inside a picture's empty frame.
func _size(texture : Texture2D) -> Vector2:
	return texture.get_size() - Vector2(2 * PART_PADDING, 2 * PART_PADDING)


func _draw_part(texture : Texture2D, at : Vector2) -> void:
	_draw_region(texture, Rect2(at, _size(texture)), Vector2.ZERO)


## Draws the art from `art_offset` inside the frame into `target`, at the target's size.
func _draw_region(texture : Texture2D, target : Rect2, art_offset : Vector2, color : Color = Color.WHITE) -> void:
	var source := Rect2(Vector2(PART_PADDING, PART_PADDING) + art_offset, target.size)
	draw_texture_rect_region(texture, target, source, color)
