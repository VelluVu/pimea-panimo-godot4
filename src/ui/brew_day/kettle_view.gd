class_name KettleView
extends Control

## The kettle from the front and a little above: liquid, clumps, foam and the springy paddle
## (the blade breaks clumps, the shaft pushes them), pellets from carried sacks, and steam.

## The stick moved this frame, in liquid pixels (see MashSession.paddle_moved).
signal paddle_moved(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float)
## The paddle hit a kettle wall; speed in pixels a second.
signal paddle_knocked(speed : float)

const ART : BrewDayArt = preload("res://src/resources/brew_day/brew_day_art.tres")
## The mouth's bounding box, the transparent hole in the sprite; the liquid is the ellipse
## inside it.
const LIQUID_RECT : Rect2 = Rect2(Vector2(24, 44), MashSession.LIQUID_SIZE)
## The liquid reaches this far under the kettle's rim, so no gap shows at its edge.
const LIQUID_UNDER_RIM : float = 4.0
## The blade keeps a little inside the mouth.
const PADDLE_MOUTH : Rect2 = Rect2(LIQUID_RECT.position + Vector2(4, 4), MashSession.LIQUID_SIZE - Vector2(8, 8))
const PADDLE_REST : Vector2 = Vector2(196, 120)
## Grabbing works a little outside the liquid too, at its edge, and anywhere on the
## shaft near the hand's spot just above the blade.
const GRAB_MARGIN : float = 10.0
const GRIP_GRAB_RADIUS : float = 16.0
const SHAFT_WIDTH : float = 3.0
const WATER_COLOR : Color = Color(0.36, 0.45, 0.5)
const CLUMP_LIGHT : Color = Color(0.85, 0.72, 0.48)
const FLASH_COLOR : Color = Color(1, 0.97, 0.85)
## The steam rect: its bottom edge on the back half of the liquid, rising above the rim.
const STEAM_RECT : Rect2 = Rect2(24, -56, 232, 170)
## A clump flashes by drawing its sprite brighter.
const FLASH_MODULATE : Color = Color(1.8, 1.8, 1.6)
const FOAM_COLOR : Color = Color(0.93, 0.89, 0.78)
const PADDLE_COLOR : Color = Color(0.6, 0.42, 0.22)
const PADDLE_SHADE : Color = Color(0.42, 0.28, 0.14)
## The blade and lowest shaft are under the wort: drawn under the clumps and foam, tinted
## and shifted like a stick in water.
const SUBMERGED_SEGMENTS : int = PaddleBody.BLADE_SEGMENTS + 1
const REFRACTION : Vector2 = Vector2(0, 2)
## The liquid shows through the submerged part this much at full murk.
const SUBMERGED_HIDE : float = 0.8
## Ripples ring the spot where the shaft enters the liquid; a moving shaft leaves a wake.
const RIPPLE_SECONDS : float = 0.7
const RIPPLE_RADIUS : float = 10.0
const RIPPLE_SQUASH : float = 0.45
const WAKE_FROM_SPEED : float = 60.0
const WAKE_PER_SPEED : float = 0.06
const WAKE_MAX : float = 16.0
const WAKE_SPREAD : float = 0.45
const BUBBLE_COLOR : Color = Color(1, 1, 1, 0.5)
## Everything that moves on its own steps at this rate, like the rest of the pixel art.
const ANIMATION_FPS : float = 10.0
const BUBBLE_COUNT : int = 14
## Each landed pellet tints the whole wort this much toward its colour.
const WORT_TINT_PER_PELLET : float = 0.0025
const FLASH_SECONDS : float = 0.25
const BURST_SECONDS : float = 0.4
const BURST_DOTS : int = 8
const BURST_REACH : float = 16.0

var liquid_color : Color = WATER_COLOR
## How much the liquid hides what is under it, 0 (clear water) to 1 (thick mash).
var murk : float = 0.3
var clumps : Array[MashClump] = []
var foam : float = 0.0
var bubbling : bool = false
## Mirrors the thermometer needle's colour on the rim.
var glow_color : Color = Color.TRANSPARENT
## 0..1, how thick the steam over the mouth is.
var steam : float = 0.0:
	set(value):
		steam = value
		if _steam_material != null:
			_steam_material.set_shader_parameter(&"intensity", value)

var _steam_material : ShaderMaterial

var _paddle : PaddleBody = PaddleBody.new(PADDLE_MOUTH, PADDLE_REST)
var _dragging : bool = false
var _target : Vector2 = PADDLE_REST
var _clock : float = 0.0
## Clump -> seconds left of its hit flash.
var _flashes : Dictionary = {}
## [liquid position, seconds left] of each breaking clump's splash.
var _bursts : Array = []
var _pours : SackPours = SackPours.new()
var _surface : WortSurface = WortSurface.new(PADDLE_REST)
var _last_entry : Vector2 = PADDLE_REST
var _entry_velocity : Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = ART.kettle.get_size() * BrewDayArt.KETTLE_SCALE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_paddle.knocked.connect(paddle_knocked.emit)
	_pours.landed.connect(_on_pellet_landed)
	_add_steam()


func _process(delta : float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	var before : PackedVector2Array = _paddle.points.duplicate()
	# The pointer holds the shaft just above the blade, so the blade goes below it.
	_paddle.step(delta, _paddle.tip_for_grip(_target) if _dragging else _target, _dragging)
	# Only a held paddle stirs; drifting back to rest touches nothing.
	if _dragging:
		paddle_moved.emit(_to_liquid(before), _to_liquid(_paddle.points), PaddleBody.POINTS - 1 - PaddleBody.BLADE_SEGMENTS, delta)
	_surface.stir(_paddle.points[0], _dragging, bubbling, delta)
	var entry : Vector2 = _paddle.points[SUBMERGED_SEGMENTS]
	if delta > 0.0:
		_entry_velocity = _entry_velocity.lerp((entry - _last_entry) / delta, minf(1.0, delta * 12.0))
	_last_entry = entry
	for clump : MashClump in _flashes.keys():
		_flashes[clump] -= delta
		if _flashes[clump] <= 0.0:
			_flashes.erase(clump)
	for i : int in range(_bursts.size() - 1, -1, -1):
		_bursts[i][1] -= delta
		if _bursts[i][1] <= 0.0:
			_bursts.remove_at(i)
	_pours.step(delta)
	_surface.step(delta)
	queue_redraw()


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		var on_mouth : bool = _paddle.inside_mouth(button.position).distance_to(button.position) <= GRAB_MARGIN
		if button.pressed and (on_mouth or _paddle.grip().distance_to(button.position) <= GRIP_GRAB_RADIUS):
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
	clear_pours()


func flash_clump(clump : MashClump) -> void:
	_flashes[clump] = FLASH_SECONDS


func burst_clump(clump : MashClump) -> void:
	_flashes.erase(clump)
	_bursts.append([clump.position, BURST_SECONDS])


## Lifts a sack: following the pointer, or hung at its own spot when lifted by key.
## Without blooms its pellets only splash.
func carry(id : int, color : Color, follow : bool, blooms : bool = true) -> void:
	_pours.carry(id, color, follow, blooms, get_local_mouse_position())


func drop(id : int) -> void:
	_pours.drop(id)


func is_carrying(id : int) -> bool:
	return _pours.is_carrying(id)


## Where the carried sack should hang: centred on `point`.
func set_carry_target(id : int, point : Vector2) -> void:
	_pours.set_target(id, point)


## True while the carried sack's mouth is above the kettle mouth, so it pours in.
func is_over_mouth(id : int) -> bool:
	return _pours.is_over_mouth(id)


## Starts or stops a carried sack's stream of pellets.
func set_pouring(id : int, pouring : bool) -> void:
	_pours.set_pouring(id, pouring)


## A handful tipped in at once from a carried sack, like spices.
func drop_handful(id : int, count : int) -> void:
	_pours.drop_handful(id, count)


func sparkle(color : Color) -> void:
	_surface.sparkle(color)


func clear_pours() -> void:
	_pours.clear()
	_surface.clear()


## Pellets outside the mouth vanish on the rim; the rest splash, and hops tint the wort.
func _on_pellet_landed(at : Vector2, color : Color, blooms : bool) -> void:
	if KettleShapes.in_ellipse(PADDLE_MOUTH, at) and _surface.land(at, color, blooms):
		liquid_color = liquid_color.lerp(color, WORT_TINT_PER_PELLET)


func _add_steam() -> void:
	_steam_material = ShaderMaterial.new()
	_steam_material.shader = ART.steam_shader
	_steam_material.set_shader_parameter(&"rect_size", STEAM_RECT.size)
	_steam_material.set_shader_parameter(&"intensity", steam)
	var rect := ColorRect.new()
	rect.material = _steam_material
	rect.position = STEAM_RECT.position
	rect.size = STEAM_RECT.size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


## Handle first and blade last, as MashSession.paddle_moved expects, in liquid pixels.
func _to_liquid(points : PackedVector2Array) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for i : int in range(points.size() - 1, -1, -1):
		moved.append(points[i] - LIQUID_RECT.position)
	return moved


func _draw() -> void:
	# The liquid and all in it go under the kettle sprite, so its rim hides their edges.
	KettleShapes.fill_ellipse(self, LIQUID_RECT.grow(LIQUID_UNDER_RIM), liquid_color)
	_surface.draw_under(self, liquid_color)
	_draw_paddle_under()
	_draw_entry_ripples()
	if bubbling:
		_draw_bubbles()
	for clump : MashClump in clumps:
		if not clump.is_broken():
			_draw_clump(clump)
	_draw_bursts()
	if foam > 0.0:
		var foam_size : Vector2 = (LIQUID_RECT.size * clampf(foam, 0.0, 1.0)).round()
		KettleShapes.fill_ellipse(self, Rect2(LIQUID_RECT.get_center() - foam_size / 2.0, foam_size), FOAM_COLOR)
	_surface.draw_rings(self)
	draw_texture_rect(ART.kettle, Rect2(Vector2.ZERO, custom_minimum_size), false)
	if glow_color.a > 0.0:
		KettleShapes.outline_ellipse(self, LIQUID_RECT.grow(4), glow_color, 2.0)
	_draw_paddle()
	_pours.draw(self, _clock)
	_surface.draw_sparkles(self)


## The clump sprite's first frame, or its second once hit; it shakes and brightens
## while it flashes.
func _draw_clump(clump : MashClump) -> void:
	var frame_size := Vector2(ART.clump.get_height(), ART.clump.get_height())
	var shown : Vector2 = frame_size * BrewDayArt.PROP_SCALE
	var at : Vector2 = (LIQUID_RECT.position + clump.position - shown / 2.0).round()
	var hit : bool = clump.swipes_left < MashSession.SWIPES_PER_CLUMP
	var flashing : bool = _flashes.has(clump)
	if flashing:
		var shake : int = int(_clock * ANIMATION_FPS * 2.0)
		at.x += 1.0 if shake % 2 == 0 else -1.0
	var region := Rect2(Vector2(frame_size.x if hit else 0.0, 0.0), frame_size)
	draw_texture_rect_region(ART.clump, Rect2(at, shown), region, FLASH_MODULATE if flashing else Color.WHITE)


## Grain bits fly out from a broken clump in steps, then blink out.
func _draw_bursts() -> void:
	for burst : Array in _bursts:
		var flown : float = KettleShapes.stepped(1.0 - burst[1] / BURST_SECONDS, BURST_SECONDS * ANIMATION_FPS * 2.0)
		for i : int in BURST_DOTS:
			var direction := Vector2.from_angle(TAU * i / BURST_DOTS)
			var at : Vector2 = LIQUID_RECT.position + burst[0] + direction * BURST_REACH * flown
			draw_rect(Rect2(at.round(), Vector2(2, 2)), CLUMP_LIGHT if i % 2 == 0 else FLASH_COLOR)


## The shaft above the wort as a bent polyline, and the grip turned along the stick;
## the rest is drawn under the liquid.
func _draw_paddle() -> void:
	var points : PackedVector2Array = _paddle.points
	var shaft : PackedVector2Array = points.slice(SUBMERGED_SEGMENTS)
	draw_polyline(shaft, PADDLE_SHADE, SHAFT_WIDTH + 2.0)
	draw_polyline(shaft, PADDLE_COLOR, SHAFT_WIDTH)
	var last : int = points.size() - 1
	_draw_turned(ART.paddle_grip, points[last], (points[last] - points[last - 1]).angle())


## The blade and the shaft's first stretch under the wort, tinted by it and shifted a
## little at the waterline.
func _draw_paddle_under() -> void:
	var points : PackedVector2Array = _paddle.points
	# Drawn see-through over the liquid, so a thick mash all but hides the blade.
	var tint : Color = Color(1, 1, 1, 1.0 - clampf(murk, 0.0, 1.0) * SUBMERGED_HIDE)
	var under : PackedVector2Array = PackedVector2Array()
	for i : int in SUBMERGED_SEGMENTS + 1:
		under.append(points[i] + REFRACTION)
	draw_polyline(under, PADDLE_SHADE * tint, SHAFT_WIDTH + 2.0)
	draw_polyline(under, PADDLE_COLOR * tint, SHAFT_WIDTH)
	var blade_end : Vector2 = points[PaddleBody.BLADE_SEGMENTS] + REFRACTION
	var tip : Vector2 = points[0] + REFRACTION
	_draw_turned(ART.paddle_blade, (tip + blade_end) / 2.0, (tip - blade_end).angle(), tint)


## Rings spread from where the shaft meets the liquid; a moving shaft trails a wake.
func _draw_entry_ripples() -> void:
	var entry : Vector2 = _paddle.points[SUBMERGED_SEGMENTS]
	if not _paddle.inside_mouth(entry).is_equal_approx(entry):
		return
	var ripple : Color = liquid_color.lightened(0.5)
	for offset : float in [0.0, 0.5]:
		var progress : float = fmod(_clock / RIPPLE_SECONDS + offset, 1.0)
		var radius : float = roundf(lerpf(2.0, RIPPLE_RADIUS, progress))
		var ring_size := Vector2(radius, radius * RIPPLE_SQUASH)
		KettleShapes.outline_ellipse(self, Rect2(entry - ring_size, ring_size * 2.0), Color(ripple, 1.0 - progress * 0.7), 2.0)
	var speed : float = _entry_velocity.length()
	if speed < WAKE_FROM_SPEED:
		return
	var back : Vector2 = -_entry_velocity.normalized() * minf(WAKE_MAX, speed * WAKE_PER_SPEED)
	for side : float in [-WAKE_SPREAD, WAKE_SPREAD]:
		draw_line(entry, entry + back.rotated(side), ripple, 2.0)


func _draw_turned(texture : Texture2D, center : Vector2, angle : float, tint : Color = Color.WHITE) -> void:
	draw_set_transform(center.round(), angle, Vector2.ONE * BrewDayArt.PROP_SCALE)
	draw_texture(texture, -texture.get_size() / 2.0, tint)
	draw_set_transform(Vector2.ZERO)


func _draw_bubbles() -> void:
	var frame : int = int(_clock * ANIMATION_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, floori(frame / 3.0)))
		var at : Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.9
		draw_rect(Rect2((LIQUID_RECT.get_center() + at * LIQUID_RECT.size / 2.0).round(), Vector2(2, 2)), BUBBLE_COLOR)
