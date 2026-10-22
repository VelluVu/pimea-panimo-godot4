class_name BrewDayPopups
extends Control

## The brew day's humour lines: each rises from the kettle mouth and blinks out, waiting its
## turn (MIN_GAP) and starting lower while earlier ones still rise.

const RISE : float = 36.0
const SECONDS : float = 1.6
const MIN_GAP : float = 0.7
## Lines still rising push a new one down by this much, a few rows deep.
const ROW_STEP : float = 14.0
const ROWS : int = 3
const MAX_QUEUE : int = 3
const GOOD_COLOR : Color = Color(0.55, 0.95, 0.5)
const BAD_COLOR : Color = Color(0.98, 0.45, 0.38)
const PLAIN_COLOR : Color = Color(0.95, 0.88, 0.7)
const DIRECTIONS : Array[Vector2] = [Vector2(-1, -0.6), Vector2(0, -1), Vector2(1, -0.6)]
## A call (the next hops) is twice the size, rises straight up and jumps the queue.
const CALL_FONT_SIZE : int = 32
const CALL_SECONDS : float = 2.0

## Where the lines start, in this control's space.
var origin : Vector2 = Vector2.ZERO
## The lines stay inside these left and right edges.
var bounds : Rect2 = Rect2(0, 0, 640, 360)

var _queue : Array = []
var _wait : float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_line(text : String, color : Color = PLAIN_COLOR) -> void:
	if text.is_empty() or _queue.size() >= MAX_QUEUE:
		return
	_queue.append([text, color, false])


## A big line straight up from the kettle, shown before anything waiting.
func show_call(text : String, color : Color) -> void:
	_queue.push_front([text, color, true])


func clear() -> void:
	_queue.clear()
	for child : Node in get_children():
		child.queue_free()


func _process(delta : float) -> void:
	_wait -= delta
	if _wait > 0.0 or _queue.is_empty():
		return
	var entry : Array = _queue.pop_front()
	_spawn(entry[0], entry[1], entry[2])
	_wait = MIN_GAP


func _spawn(text : String, color : Color, call : bool) -> void:
	var label := Label.new()
	label.text = tr(text)
	if call:
		label.add_theme_font_size_override("font_size", CALL_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6 if call else 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var direction : Vector2 = Vector2.UP if call else DIRECTIONS[randi() % DIRECTIONS.size()]
	var width : float = label.get_minimum_size().x
	var row : int = (get_child_count() - 1) % ROWS
	var start : Vector2 = origin - Vector2(width * (0.5 - direction.x * 0.5), -row * ROW_STEP)
	var end : Vector2 = start + direction * RISE
	var shift : float = clampf(end.x, bounds.position.x, bounds.end.x - width) - end.x
	start.x += shift
	end.x += shift
	label.position = start.round()
	var tween : Tween = label.create_tween()
	PixelStepTween.move_property(tween, label, &"position", start.round(), end.round(), CALL_SECONDS if call else SECONDS)
	tween.tween_callback(label.queue_free)
