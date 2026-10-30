class_name NextStepPointer
extends Control

## Shows where the next click goes: a bobbing arrow above a spot in the cellar, a blinking
## frame around a button, or both for a doorway: a frame and an arrow at its left. Never takes the mouse. It sits just above the window that holds
## its target, so windows opened over that one cover it.

enum Style { ARROW_ABOVE, FRAME, FRAME_ARROW_LEFT }

const ARROW_RIGHT_TEXT : String = "▶"
## Five font pixels at ARROW_FONT_SIZE.
const ARROW_RIGHT_HEIGHT : float = 15.0
const ARROW_TEXT : String = "▼"
## Icon glyphs need a multiple of 16; at 48 the 5 px arrow is 15 px wide.
const ARROW_FONT_SIZE : int = 48
const ARROW_GAP : float = 4.0
const OUTLINE_SIZE : int = 6
const COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # the goals panel's gold
const OUTLINE_COLOR : Color = Color(0.08235294, 0.0627451, 0.039215688, 1)
const FRAME_WIDTH : float = 2.0
## Whole steps, not a smooth sine: a half-pixel bob blurs the pixel art.
const BEAT_SECONDS : float = 0.4
const BOB_PIXELS : float = 2.0

var _target : Control = null
var _style : Style = Style.FRAME
var _elapsed : float = 0.0
var _arrow_drop : float = 0.0
## Part of the target to mark, in its own coordinates; empty marks all of it.
var _area : Rect2 = Rect2()
## The pointer never sits lower than just above this sibling (the bar's views). Null keeps
## it where its parent put it, e.g. last in a full-screen window.
var _floor : Control = null


## `floor` is a sibling of the pointer; see _floor.
func _init(floor : Control = null) -> void:
	_floor = floor


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The recipe book pauses the game while the pointer guides through it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


## `target` null hides the pointer. `arrow_drop` lowers the arrow into the target, for a
## spot whose picture starts below its rect's top. `area` marks only that part of the
## target, in its own coordinates.
func point_at(target : Control, style : Style, arrow_drop : float = 0.0, area : Rect2 = Rect2()) -> void:
	if target == _target and style == _style and arrow_drop == _arrow_drop and area == _area:
		return
	_target = target
	_style = style
	_arrow_drop = arrow_drop
	_area = area
	_elapsed = 0.0
	set_process(target != null)
	if target != null and _floor != null:
		_raise_above_host(target)
	queue_redraw()


## A frame moves just above the target's window (its ancestor among the pointer's
## siblings) when that is above the floor. An arrow marks a spot in the cellar and stays at
## the floor: its hover label sits above some windows, which must still cover the arrow.
func _raise_above_host(target : Control) -> void:
	var host : Node = target
	while host != null and host.get_parent() != get_parent():
		host = host.get_parent()
	if host == null or host == self:
		return
	var above : Node = host if _style == Style.FRAME and host.get_index() > _floor.get_index() else _floor
	var index : int = above.get_index()
	get_parent().move_child(self, index if get_index() < index else index + 1)


func _process(delta : float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if _target == null or not is_instance_valid(_target) or not _is_shown(_target):
		return

	var rect := Rect2((_target.global_position - global_position).round(), _target.size.round())
	if _area.has_area():
		rect = Rect2(rect.position + _area.position.round(), _area.size.round())
	var on_beat : bool = int(_elapsed / BEAT_SECONDS) % 2 == 0
	match _style:
		Style.FRAME:
			if on_beat:
				# Kept on screen: a top-bar button's frame would lose its top edge.
				_draw_frame(rect.grow(FRAME_WIDTH).intersection(Rect2(Vector2.ZERO, size)))
		Style.ARROW_ABOVE:
			_draw_arrow(rect, 0.0 if on_beat else -BOB_PIXELS)
		Style.FRAME_ARROW_LEFT:
			if on_beat:
				_draw_frame(rect.grow(FRAME_WIDTH).intersection(Rect2(Vector2.ZERO, size)))
			_draw_arrow_left(rect, 0.0 if on_beat else -BOB_PIXELS)


## An arrow may mark a spot by its hover label, which stays hidden until hovered.
func _is_shown(target : Control) -> bool:
	if _style != Style.FRAME:
		return target.get_parent() is CanvasItem and (target.get_parent() as CanvasItem).is_visible_in_tree()
	return target.is_visible_in_tree()


func _draw_frame(rect : Rect2) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, FRAME_WIDTH)), COLOR)
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - FRAME_WIDTH), Vector2(rect.size.x, FRAME_WIDTH)), COLOR)
	draw_rect(Rect2(rect.position, Vector2(FRAME_WIDTH, rect.size.y)), COLOR)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - FRAME_WIDTH, 0.0), Vector2(FRAME_WIDTH, rect.size.y)), COLOR)


func _draw_arrow(rect : Rect2, bob : float) -> void:
	var font : Font = get_theme_font(&"font", &"Label")
	var arrow_size : Vector2 = font.get_string_size(ARROW_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE)
	var baseline := Vector2(rect.get_center().x - arrow_size.x / 2.0, rect.position.y + _arrow_drop - ARROW_GAP + bob).round()
	draw_string_outline(font, baseline, ARROW_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE, OUTLINE_SIZE, OUTLINE_COLOR)
	draw_string(font, baseline, ARROW_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE, COLOR)


## The ▶ sits on its baseline, so the baseline goes half its height below the middle.
func _draw_arrow_left(rect : Rect2, bob : float) -> void:
	var font : Font = get_theme_font(&"font", &"Label")
	var arrow_width : float = font.get_string_size(ARROW_RIGHT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE).x
	var x : float = rect.position.x - FRAME_WIDTH - ARROW_GAP - arrow_width + bob
	var baseline := Vector2(x, rect.get_center().y + ARROW_RIGHT_HEIGHT / 2.0).round()
	draw_string_outline(font, baseline, ARROW_RIGHT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE, OUTLINE_SIZE, OUTLINE_COLOR)
	draw_string(font, baseline, ARROW_RIGHT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ARROW_FONT_SIZE, COLOR)
