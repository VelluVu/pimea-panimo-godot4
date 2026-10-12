class_name KettleView
extends Control

## The brew day's kettle, drawn with placeholder shapes until the real sprites exist:
## the pot, the liquid seen from above, the clumps, the foam and the paddle. Dragging on
## the liquid moves the paddle; its blade tip follows the pointer with a little lag.

signal paddle_moved(liquid_position : Vector2)

const LIQUID_RECT : Rect2 = Rect2(24, 12, 232, 104)
const BODY_RECT : Rect2 = Rect2(12, 40, 256, 224)
const RIM_RECT : Rect2 = Rect2(12, 112, 256, 12)
const HANDLE_SIZE : Vector2 = Vector2(12, 28)
const PADDLE_PIVOT : Vector2 = Vector2(262, 4)
const PADDLE_REST : Vector2 = Vector2(0.88, 0.75)
const PADDLE_FOLLOW : float = 14.0
const PADDLE_WIDTH : float = 4.0
const CLUMP_RADIUS_PX : float = 9.0
const WATER_COLOR : Color = Color(0.36, 0.45, 0.5)
const BODY_COLOR : Color = Color(0.42, 0.44, 0.47)
const BODY_SHADE : Color = Color(0.3, 0.31, 0.34)
const RIM_COLOR : Color = Color(0.55, 0.57, 0.6)
const CLUMP_COLOR : Color = Color(0.62, 0.47, 0.28)
const CLUMP_SHADE : Color = Color(0.45, 0.33, 0.19)
const FOAM_COLOR : Color = Color(0.93, 0.89, 0.78)
const PADDLE_COLOR : Color = Color(0.6, 0.42, 0.22)
const BUBBLE_COLOR : Color = Color(1, 1, 1, 0.5)
## Bubbles move in steps, like the rest of the pixel art.
const BUBBLE_FPS : float = 10.0
const BUBBLE_COUNT : int = 14

var liquid_color : Color = WATER_COLOR
var clumps : Array[MashClump] = []
var foam : float = 0.0
var bubbling : bool = false
## Mirrors the thermometer needle's colour on the rim.
var glow_color : Color = Color.TRANSPARENT

var _dragging : bool = false
var _tip : Vector2 = PADDLE_REST
var _tip_target : Vector2 = PADDLE_REST
var _bubble_clock : float = 0.0


func _ready() -> void:
	custom_minimum_size = BODY_RECT.end + Vector2(HANDLE_SIZE.x, 0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta : float) -> void:
	if not is_visible_in_tree():
		return
	var before : Vector2 = _tip
	_tip = _tip.lerp(_tip_target, minf(1.0, delta * PADDLE_FOLLOW))
	if _dragging and before.distance_to(_tip) > 0.0005:
		paddle_moved.emit(_tip)
	_bubble_clock += delta
	queue_redraw()


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed and LIQUID_RECT.has_point(button.position):
			_dragging = true
			_tip_target = _to_liquid(button.position)
		elif not button.pressed:
			_dragging = false
			_tip_target = PADDLE_REST
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_tip_target = _to_liquid((event as InputEventMouseMotion).position)
		accept_event()


func reset_paddle() -> void:
	_dragging = false
	_tip = PADDLE_REST
	_tip_target = PADDLE_REST


func _draw() -> void:
	var left_handle := Rect2(BODY_RECT.position.x - HANDLE_SIZE.x, BODY_RECT.position.y + 60, HANDLE_SIZE.x, HANDLE_SIZE.y)
	var right_handle := Rect2(BODY_RECT.end.x, BODY_RECT.position.y + 60, HANDLE_SIZE.x, HANDLE_SIZE.y)
	draw_rect(left_handle, BODY_SHADE)
	draw_rect(right_handle, BODY_SHADE)
	draw_rect(BODY_RECT, BODY_COLOR)
	draw_rect(Rect2(BODY_RECT.position + Vector2(BODY_RECT.size.x - 24, 0), Vector2(24, BODY_RECT.size.y)), BODY_SHADE)
	draw_rect(LIQUID_RECT.grow(4), BODY_SHADE)
	draw_rect(LIQUID_RECT, liquid_color)
	if bubbling:
		_draw_bubbles()
	for clump : MashClump in clumps:
		if clump.is_broken():
			continue
		var at : Vector2 = _from_liquid(clump.position)
		var radius : float = CLUMP_RADIUS_PX * (0.7 if clump.swipes_left < MashSession.SWIPES_PER_CLUMP else 1.0)
		draw_circle(at + Vector2(1, 2), radius, CLUMP_SHADE)
		draw_circle(at, radius, CLUMP_COLOR)
	if foam > 0.0:
		var foam_height : float = LIQUID_RECT.size.y * clampf(foam, 0.0, 1.0)
		draw_rect(Rect2(LIQUID_RECT.position, Vector2(LIQUID_RECT.size.x, foam_height)), FOAM_COLOR)
	draw_line(PADDLE_PIVOT, _from_liquid(_tip), PADDLE_COLOR, PADDLE_WIDTH)
	draw_rect(Rect2(_from_liquid(_tip) - Vector2(5, 3), Vector2(10, 6)), PADDLE_COLOR)
	draw_rect(RIM_RECT, RIM_COLOR)
	if glow_color.a > 0.0:
		draw_rect(LIQUID_RECT.grow(4), glow_color, false, 2.0)


func _draw_bubbles() -> void:
	var frame : int = int(_bubble_clock * BUBBLE_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, frame / 3))
		var at := Vector2(rng.randf(), rng.randf())
		draw_rect(Rect2(_from_liquid(at).round(), Vector2(2, 2)), BUBBLE_COLOR)


func _to_liquid(point : Vector2) -> Vector2:
	return ((point - LIQUID_RECT.position) / LIQUID_RECT.size).clamp(Vector2.ZERO, Vector2.ONE)


func _from_liquid(point : Vector2) -> Vector2:
	return LIQUID_RECT.position + point * LIQUID_RECT.size
