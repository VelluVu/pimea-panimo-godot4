class_name KettleView
extends Control

## The brew day's kettle, drawn with placeholder shapes until the real sprites exist:
## the pot, the liquid seen from above, the clumps, the foam and the paddle. The paddle
## hangs from a grip above the back rim and swings around it: dragging turns it toward
## the pointer, a little behind like a real sweep, and the part in the liquid is what
## touches the clumps.

signal paddle_swept(from : Vector2, to : Vector2)

const LIQUID_RECT : Rect2 = Rect2(Vector2(24, 12), MashSession.LIQUID_SIZE)
const BODY_RECT : Rect2 = Rect2(12, 40, 256, 224)
const RIM_RECT : Rect2 = Rect2(12, 112, 256, 12)
const HANDLE_SIZE : Vector2 = Vector2(12, 28)
const PADDLE_PIVOT : Vector2 = Vector2(140, -6)
## Angles from straight down; positive swings to the right.
const PADDLE_REST_ANGLE : float = deg_to_rad(38.0)
const PADDLE_MAX_ANGLE : float = deg_to_rad(80.0)
const PADDLE_FOLLOW : float = 12.0
const SHAFT_WIDTH : float = 3.0
const BLADE_WIDTH : float = 7.0
const BLADE_LENGTH : float = 22.0
const GRIP_SIZE : Vector2 = Vector2(8, 6)
const CLUMP_RADIUS_PX : float = MashSession.CLUMP_RADIUS
const WATER_COLOR : Color = Color(0.36, 0.45, 0.5)
const BODY_COLOR : Color = Color(0.42, 0.44, 0.47)
const BODY_SHADE : Color = Color(0.3, 0.31, 0.34)
const RIM_COLOR : Color = Color(0.55, 0.57, 0.6)
const CLUMP_COLOR : Color = Color(0.7, 0.55, 0.33)
const CLUMP_LIGHT : Color = Color(0.85, 0.72, 0.48)
const CLUMP_SHADE : Color = Color(0.42, 0.31, 0.18)
const FLASH_COLOR : Color = Color(1, 0.97, 0.85)
const FOAM_COLOR : Color = Color(0.93, 0.89, 0.78)
const PADDLE_COLOR : Color = Color(0.6, 0.42, 0.22)
const PADDLE_SHADE : Color = Color(0.42, 0.28, 0.14)
const BUBBLE_COLOR : Color = Color(1, 1, 1, 0.5)
## Everything that moves on its own steps at this rate, like the rest of the pixel art.
const ANIMATION_FPS : float = 10.0
const BUBBLE_COUNT : int = 14
const FLASH_SECONDS : float = 0.25
const BURST_SECONDS : float = 0.4
const BURST_DOTS : int = 8
const BURST_REACH : float = 16.0

var liquid_color : Color = WATER_COLOR
var clumps : Array[MashClump] = []
var foam : float = 0.0
var bubbling : bool = false
## Mirrors the thermometer needle's colour on the rim.
var glow_color : Color = Color.TRANSPARENT

var _dragging : bool = false
var _angle : float = PADDLE_REST_ANGLE
var _angle_target : float = PADDLE_REST_ANGLE
var _clock : float = 0.0
## Clump -> seconds left of its hit flash.
var _flashes : Dictionary = {}
## [liquid position, seconds left] of each breaking clump's splash.
var _bursts : Array = []


func _ready() -> void:
	custom_minimum_size = BODY_RECT.end + Vector2(HANDLE_SIZE.x, 0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta : float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	_angle = lerp_angle(_angle, _angle_target, minf(1.0, delta * PADDLE_FOLLOW))
	# Only a held paddle stirs; swinging back to rest touches nothing.
	if _dragging:
		var blade : PackedVector2Array = _blade_in_liquid()
		if blade.size() == 2:
			paddle_swept.emit(blade[0] - LIQUID_RECT.position, blade[1] - LIQUID_RECT.position)
	for clump : MashClump in _flashes.keys():
		_flashes[clump] -= delta
		if _flashes[clump] <= 0.0:
			_flashes.erase(clump)
	for i : int in range(_bursts.size() - 1, -1, -1):
		_bursts[i][1] -= delta
		if _bursts[i][1] <= 0.0:
			_bursts.remove_at(i)
	queue_redraw()


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed and LIQUID_RECT.has_point(button.position):
			_dragging = true
			_aim_at(button.position)
		elif not button.pressed:
			_dragging = false
			_angle_target = PADDLE_REST_ANGLE
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_aim_at((event as InputEventMouseMotion).position)
		accept_event()


func reset_paddle() -> void:
	_dragging = false
	_angle = PADDLE_REST_ANGLE
	_angle_target = PADDLE_REST_ANGLE
	_flashes.clear()
	_bursts.clear()


func flash_clump(clump : MashClump) -> void:
	_flashes[clump] = FLASH_SECONDS


func burst_clump(clump : MashClump) -> void:
	_flashes.erase(clump)
	_bursts.append([clump.position, BURST_SECONDS])


func _aim_at(point : Vector2) -> void:
	var offset : Vector2 = point - PADDLE_PIVOT
	_angle_target = clampf(atan2(offset.x, offset.y), -PADDLE_MAX_ANGLE, PADDLE_MAX_ANGLE)


func _direction() -> Vector2:
	return Vector2(sin(_angle), cos(_angle))


## Where the paddle enters the liquid and where its tip stops at the far edge, or an
## empty array when it misses the liquid.
func _blade_in_liquid() -> PackedVector2Array:
	var direction : Vector2 = _direction()
	var enter : float = 0.0
	var leave : float = INF
	for axis : int in 2:
		var low : float = LIQUID_RECT.position[axis]
		var high : float = LIQUID_RECT.end[axis]
		if absf(direction[axis]) < 0.00001:
			if PADDLE_PIVOT[axis] < low or PADDLE_PIVOT[axis] > high:
				return PackedVector2Array()
			continue
		var t1 : float = (low - PADDLE_PIVOT[axis]) / direction[axis]
		var t2 : float = (high - PADDLE_PIVOT[axis]) / direction[axis]
		enter = maxf(enter, minf(t1, t2))
		leave = minf(leave, maxf(t1, t2))
	if leave <= enter:
		return PackedVector2Array()
	return PackedVector2Array([PADDLE_PIVOT + direction * enter, PADDLE_PIVOT + direction * leave])


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
		if not clump.is_broken():
			_draw_clump(clump)
	_draw_bursts()
	if foam > 0.0:
		var foam_height : float = LIQUID_RECT.size.y * clampf(foam, 0.0, 1.0)
		draw_rect(Rect2(LIQUID_RECT.position, Vector2(LIQUID_RECT.size.x, foam_height)), FOAM_COLOR)
	_draw_paddle()
	draw_rect(RIM_RECT, RIM_COLOR)
	if glow_color.a > 0.0:
		draw_rect(LIQUID_RECT.grow(4), glow_color, false, 2.0)


## A lumpy blob of three circles; a hit one is smaller and paler, and shakes while it
## flashes.
func _draw_clump(clump : MashClump) -> void:
	var at : Vector2 = LIQUID_RECT.position + clump.position
	var hit : bool = clump.swipes_left < MashSession.SWIPES_PER_CLUMP
	var radius : float = roundf(CLUMP_RADIUS_PX * (0.65 if hit else 0.85))
	var flashing : bool = _flashes.has(clump)
	if flashing:
		var frame : int = int(_clock * ANIMATION_FPS * 2.0)
		at.x += 1.0 if frame % 2 == 0 else -1.0
	var lumps : Array[Vector2] = [Vector2(-0.45, 0.1), Vector2(0.4, -0.15), Vector2(0.05, 0.35)]
	for lump : Vector2 in lumps:
		draw_circle((at + lump * radius + Vector2(1, 2)).round(), radius * 0.75, CLUMP_SHADE)
	for lump : Vector2 in lumps:
		draw_circle((at + lump * radius).round(), radius * 0.75, FLASH_COLOR if flashing else (CLUMP_LIGHT if hit else CLUMP_COLOR))
	draw_rect(Rect2((at + Vector2(-radius * 0.4, -radius * 0.5)).round(), Vector2(2, 2)), CLUMP_LIGHT)


## Grain bits fly out from a broken clump in steps, then blink out.
func _draw_bursts() -> void:
	for burst : Array in _bursts:
		var progress : float = 1.0 - burst[1] / BURST_SECONDS
		var stepped : float = floorf(progress * BURST_SECONDS * ANIMATION_FPS * 2.0) / (BURST_SECONDS * ANIMATION_FPS * 2.0)
		for i : int in BURST_DOTS:
			var direction := Vector2.from_angle(TAU * i / BURST_DOTS)
			var at : Vector2 = LIQUID_RECT.position + burst[0] + direction * BURST_REACH * stepped
			draw_rect(Rect2(at.round(), Vector2(2, 2)), CLUMP_LIGHT if i % 2 == 0 else FLASH_COLOR)


func _draw_paddle() -> void:
	var blade : PackedVector2Array = _blade_in_liquid()
	var tip : Vector2 = blade[1] if blade.size() == 2 else PADDLE_PIVOT + _direction() * LIQUID_RECT.size.y
	var direction : Vector2 = _direction()
	draw_line(PADDLE_PIVOT, tip, PADDLE_SHADE, SHAFT_WIDTH + 2.0)
	draw_line(PADDLE_PIVOT, tip, PADDLE_COLOR, SHAFT_WIDTH)
	var blade_start : Vector2 = tip - direction * minf(BLADE_LENGTH, tip.distance_to(PADDLE_PIVOT))
	draw_line(blade_start, tip, PADDLE_SHADE, BLADE_WIDTH + 2.0)
	draw_line(blade_start, tip, PADDLE_COLOR, BLADE_WIDTH)
	draw_rect(Rect2(PADDLE_PIVOT - GRIP_SIZE / 2.0, GRIP_SIZE), PADDLE_SHADE)


func _draw_bubbles() -> void:
	var frame : int = int(_clock * ANIMATION_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, floori(frame / 3.0)))
		var at := Vector2(rng.randf(), rng.randf())
		draw_rect(Rect2((LIQUID_RECT.position + at * LIQUID_RECT.size).round(), Vector2(2, 2)), BUBBLE_COLOR)
