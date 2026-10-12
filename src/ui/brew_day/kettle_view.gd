class_name KettleView
extends Control

## The brew day's kettle, drawn with placeholder shapes until the real sprites exist:
## a round pot seen from the front and a little above, its oval mouth full of liquid,
## the clumps, the foam and the paddle. The paddle is a springy stick (PaddleBody):
## pressing on the liquid puts its blade under the pointer, and the shaft swings around
## over the far rim behind it. The blade breaks the clumps; the shaft only pushes them.

## The stick moved this frame, in liquid pixels (see MashSession.paddle_moved).
signal paddle_moved(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float)
## The paddle hit a kettle wall; speed in pixels a second.
signal paddle_knocked(speed : float)

## The bounding box of the oval mouth; the liquid is the ellipse inside it.
const LIQUID_RECT : Rect2 = Rect2(Vector2(24, 44), MashSession.LIQUID_SIZE)
const BODY_RECT : Rect2 = Rect2(12, 96, 256, 168)
const BOTTOM_RECT : Rect2 = Rect2(12, 244, 256, 40)
const RIM_WIDTH : float = 8.0
const HANDLE_SIZE : Vector2 = Vector2(12, 28)
const ELLIPSE_POINTS : int = 48
## The blade keeps a little inside the mouth.
const PADDLE_MOUTH : Rect2 = Rect2(LIQUID_RECT.position + Vector2(4, 4), MashSession.LIQUID_SIZE - Vector2(8, 8))
const PADDLE_REST : Vector2 = Vector2(196, 120)
## Grabbing works a little outside the liquid too, at its edge.
const GRAB_MARGIN : float = 10.0
const SHAFT_WIDTH : float = 3.0
const BLADE_WIDTH : float = 7.0
const GRIP_SIZE : Vector2 = Vector2(6, 6)
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

var _paddle : PaddleBody = PaddleBody.new(PADDLE_MOUTH, PADDLE_REST)
var _dragging : bool = false
var _target : Vector2 = PADDLE_REST
var _clock : float = 0.0
## Clump -> seconds left of its hit flash.
var _flashes : Dictionary = {}
## [liquid position, seconds left] of each breaking clump's splash.
var _bursts : Array = []


func _ready() -> void:
	custom_minimum_size = BOTTOM_RECT.end + Vector2(HANDLE_SIZE.x, 0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_paddle.knocked.connect(paddle_knocked.emit)


func _process(delta : float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	var before : PackedVector2Array = _paddle.points.duplicate()
	_paddle.step(delta, _target, _dragging)
	# Only a held paddle stirs; drifting back to rest touches nothing.
	if _dragging:
		paddle_moved.emit(_to_liquid(before), _to_liquid(_paddle.points), PaddleBody.POINTS - 1 - PaddleBody.BLADE_SEGMENTS, delta)
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
		if button.pressed and _paddle.inside_mouth(button.position).distance_to(button.position) <= GRAB_MARGIN:
			_dragging = true
			_target = button.position
		elif not button.pressed:
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_target = (event as InputEventMouseMotion).position
		accept_event()


func reset_paddle() -> void:
	_dragging = false
	_target = PADDLE_REST
	_paddle.reset()
	_flashes.clear()
	_bursts.clear()


func flash_clump(clump : MashClump) -> void:
	_flashes[clump] = FLASH_SECONDS


func burst_clump(clump : MashClump) -> void:
	_flashes.erase(clump)
	_bursts.append([clump.position, BURST_SECONDS])


## Handle first and blade last, as MashSession.paddle_moved expects, in liquid pixels.
func _to_liquid(points : PackedVector2Array) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for i : int in range(points.size() - 1, -1, -1):
		moved.append(points[i] - LIQUID_RECT.position)
	return moved


func _draw() -> void:
	var handle_y : float = BODY_RECT.position.y + 50
	draw_rect(Rect2(BODY_RECT.position.x - HANDLE_SIZE.x, handle_y, HANDLE_SIZE.x, HANDLE_SIZE.y), BODY_SHADE)
	draw_rect(Rect2(BODY_RECT.end.x, handle_y, HANDLE_SIZE.x, HANDLE_SIZE.y), BODY_SHADE)
	draw_colored_polygon(_ellipse(BOTTOM_RECT), BODY_SHADE)
	draw_rect(BODY_RECT, BODY_COLOR)
	draw_rect(Rect2(BODY_RECT.end.x - 24, BODY_RECT.position.y, 24, BODY_RECT.size.y), BODY_SHADE)
	draw_colored_polygon(_ellipse(LIQUID_RECT.grow(RIM_WIDTH)), RIM_COLOR)
	draw_colored_polygon(_ellipse(LIQUID_RECT.grow(2)), BODY_SHADE)
	draw_colored_polygon(_ellipse(LIQUID_RECT), liquid_color)
	if bubbling:
		_draw_bubbles()
	for clump : MashClump in clumps:
		if not clump.is_broken():
			_draw_clump(clump)
	_draw_bursts()
	if foam > 0.0:
		var foam_size : Vector2 = (LIQUID_RECT.size * clampf(foam, 0.0, 1.0)).round()
		draw_colored_polygon(_ellipse(Rect2(LIQUID_RECT.get_center() - foam_size / 2.0, foam_size)), FOAM_COLOR)
	if glow_color.a > 0.0:
		var outline : PackedVector2Array = _ellipse(LIQUID_RECT.grow(4))
		outline.append(outline[0])
		draw_polyline(outline, glow_color, 2.0)
	_draw_paddle()


func _ellipse(rect : Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i : int in ELLIPSE_POINTS:
		var angle : float = TAU * i / ELLIPSE_POINTS
		points.append((rect.get_center() + Vector2(cos(angle), sin(angle)) * rect.size / 2.0).round())
	return points


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


## The bent shaft as a polyline, the blade at the tip wider, the grip a dark knob.
func _draw_paddle() -> void:
	var points : PackedVector2Array = _paddle.points
	draw_polyline(points, PADDLE_SHADE, SHAFT_WIDTH + 2.0)
	draw_polyline(points, PADDLE_COLOR, SHAFT_WIDTH)
	var blade : PackedVector2Array = points.slice(0, PaddleBody.BLADE_SEGMENTS + 1)
	draw_polyline(blade, PADDLE_SHADE, BLADE_WIDTH + 2.0)
	draw_polyline(blade, PADDLE_COLOR, BLADE_WIDTH)
	draw_rect(Rect2(_paddle.handle() - GRIP_SIZE / 2.0, GRIP_SIZE), PADDLE_SHADE)


func _draw_bubbles() -> void:
	var frame : int = int(_clock * ANIMATION_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, floori(frame / 3.0)))
		var at : Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.9
		draw_rect(Rect2((LIQUID_RECT.get_center() + at * LIQUID_RECT.size / 2.0).round(), Vector2(2, 2)), BUBBLE_COLOR)
