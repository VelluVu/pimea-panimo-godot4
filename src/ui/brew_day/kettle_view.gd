class_name KettleView
extends Control

## The brew day's kettle: a round pot seen from the front and a little above (its sprite
## in BrewDayArt), its oval mouth full of liquid,
## the clumps, the foam and the paddle. The paddle is a springy stick (PaddleBody):
## pressing on the liquid puts its blade under the pointer, and the shaft swings around
## over the far rim behind it. The blade breaks the clumps; the shaft only pushes them.
## In the boil a sack is carried over the mouth (following the pointer, a little behind)
## and its pellets drop into the wort, each landing with a splash ring and a coloured
## bloom that fades into the wort. Shaking it throws them diagonally to random spots.
## The malt sack pours its grains into the mash the same way, without the blooms.
## Stirring sets the wort swirling: the blooms ride the swirl around the kettle and
## leave coloured stripes behind them, and the swirl dies down slowly to the gentle
## turn of the rolling boil, which keeps drawing the stripes out. Steam rises over the
## mouth (a shader child) as strongly as `steam` says.

## The stick moved this frame, in liquid pixels (see MashSession.paddle_moved).
signal paddle_moved(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float)
## The paddle hit a kettle wall; speed in pixels a second.
signal paddle_knocked(speed : float)

const ART : BrewDayArt = preload("res://src/resources/brew_day/brew_day_art.tres")
## The bounding box of the oval mouth, the transparent hole in the kettle sprite; the
## liquid is the ellipse inside it.
const LIQUID_RECT : Rect2 = Rect2(Vector2(24, 44), MashSession.LIQUID_SIZE)
const ELLIPSE_POINTS : int = 48
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
const BUBBLE_COLOR : Color = Color(1, 1, 1, 0.5)
## Everything that moves on its own steps at this rate, like the rest of the pixel art.
const ANIMATION_FPS : float = 10.0
const BUBBLE_COUNT : int = 14
const FLASH_SECONDS : float = 0.25
const BURST_SECONDS : float = 0.4
const BURST_DOTS : int = 8
const BURST_REACH : float = 16.0
## Where a sack lifted by its key hangs over the mouth, one spot per sack at once.
const POUR_SPOTS : Array[Vector2] = [Vector2(78, 4), Vector2(170, 4), Vector2(124, -4)]
## A carried sack follows the pointer this fast, so it feels a little heavy.
const CARRY_FOLLOW : float = 16.0
## A sack moving faster than this (pixels a second) is shaking; at SHAKE_FROM plus
## SHAKE_RANGE it shakes fully: pellets pour twice as fast and fly off with its motion.
const SHAKE_FROM : float = 220.0
const SHAKE_RANGE : float = 400.0
const SHAKE_THROW : float = 0.55
const SHAKE_SCATTER : float = 60.0
## The sack's mouth pours into the kettle within this reach of the mouth's edges.
const POUR_REACH_ABOVE : float = 110.0
const POUR_INSET : float = 8.0
## Where the lifted sack sprite's mouth is (sprite pixels), for the falling pellets.
const LIFTED_SACK_MOUTH : Vector2 = Vector2(13, 16)
const PELLETS_PER_SECOND : float = 30.0
const PELLET_GRAVITY : float = 420.0
const PELLET_SIZE : Vector2 = Vector2(2, 2)
## Pellets land this far into the mouth from its top edge.
const LANDING_DEPTH : Vector2 = Vector2(18, 62)
const RING_SECONDS : float = 0.45
const RING_SIZE : Vector2 = Vector2(18, 8)
const BLOOM_SECONDS : float = 12.0
const BLOOM_SIZE : Vector2 = Vector2(40, 18)
## Colour steps a bloom takes back to the wort's colour, instead of fading.
const BLOOM_STEPS : int = 8
const MAX_BLOOMS : int = 30
## Blooms land this far from the middle at most (share of the mouth), so they stay
## inside it all the way round a swirl.
const BLOOM_REACH : float = 0.62
## How quickly the wort takes up the paddle's circling, and how slowly it lets go.
const STIR_GAIN : float = 3.0
const SWIRL_DRAG : float = 0.35
const MAX_SWIRL : float = 4.0
## A rolling boil keeps the wort turning at least this fast, in its current direction.
const BOIL_SWIRL : float = 0.5
## A swirling bloom drops a stripe stamp this often, once the swirl is this fast.
const TRAIL_INTERVAL : float = 0.08
const TRAIL_MIN_SWIRL : float = 0.3
const TRAIL_SECONDS : float = 12.0
const TRAIL_STEPS : int = 8
const TRAIL_SIZE : Vector2 = Vector2(4, 2)
const MAX_TRAILS : int = 900
## The middle of the swirl turns faster than its edge, which pulls blooms apart.
const SWIRL_CENTER_SPEED : float = 1.6
## The stripes drift slower than the floating blooms, so a bloom draws its stripe
## behind it instead of covering it.
const TRAIL_DRIFT : float = 0.35
## Stripe stamps scatter across this share of a bloom's width.
const TRAIL_SPREAD : float = 0.6
## Each landed pellet tints the whole wort this much toward its colour.
const WORT_TINT_PER_PELLET : float = 0.0025
const SPARKLE_SECONDS : float = 0.8
const SPARKLE_DOTS : int = 10
const SPARKLE_RISE : float = 40.0
const SPARKLE_COLOR : Color = Color(1.0, 0.85, 0.3)

var liquid_color : Color = WATER_COLOR
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
## Ingredient id -> [pellet colour, pellets owed to the next frame].
var _pours : Dictionary = {}
## Ingredient id -> {at (sprite's top-left), target, velocity, follow, color} of each
## sack lifted off its place.
var _carried : Dictionary = {}
## [position, velocity, landing y, colour, blooms] of each falling pellet.
var _pellets : Array = []
## [position, seconds left, colour] of splash rings.
var _rings : Array = []
## [place, seconds left, colour] of blooms and stripe stamps; the place is relative to
## the mouth's middle in a space where the mouth is a unit circle, so a swirl just
## turns it.
var _blooms : Array = []
var _trails : Array = []
## How fast the wort turns, in radians a second; positive is clockwise on screen.
var _swirl : float = 0.0
var _trail_clock : float = 0.0
var _last_tip : Vector2 = PADDLE_REST
## [colour, seconds left] of the sparkles of a perfect addition.
var _sparkles : Array = []


func _ready() -> void:
	custom_minimum_size = ART.kettle.get_size() * BrewDayArt.KETTLE_SCALE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_paddle.knocked.connect(paddle_knocked.emit)
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
	_stir(delta)
	for clump : MashClump in _flashes.keys():
		_flashes[clump] -= delta
		if _flashes[clump] <= 0.0:
			_flashes.erase(clump)
	for i : int in range(_bursts.size() - 1, -1, -1):
		_bursts[i][1] -= delta
		if _bursts[i][1] <= 0.0:
			_bursts.remove_at(i)
	_step_pours(delta)
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


## Lifts a sack: one following the pointer starts under it, one lifted by its key
## hangs at its own spot over the mouth. Without blooms its pellets only splash.
func carry(id : int, color : Color, follow : bool, blooms : bool = true) -> void:
	if _carried.has(id):
		return
	var at : Vector2 = POUR_SPOTS[_carried.size() % POUR_SPOTS.size()]
	if follow:
		at = get_local_mouse_position() - _lifted_size() / 2.0
	_carried[id] = {"at": at, "target": at, "velocity": Vector2.ZERO, "follow": follow, "color": color, "blooms": blooms}


func drop(id : int) -> void:
	_carried.erase(id)
	_pours.erase(id)


func is_carrying(id : int) -> bool:
	return _carried.has(id)


## Where the carried sack should hang: centred on `point`.
func set_carry_target(id : int, point : Vector2) -> void:
	if _carried.has(id):
		_carried[id].target = point - _lifted_size() / 2.0


## True while the carried sack's mouth is above the kettle mouth, so it pours in.
func is_over_mouth(id : int) -> bool:
	if not _carried.has(id):
		return false
	var mouth : Vector2 = _carried[id].at + LIFTED_SACK_MOUTH * BrewDayArt.PROP_SCALE
	return mouth.x > LIQUID_RECT.position.x + POUR_INSET and mouth.x < LIQUID_RECT.end.x - POUR_INSET \
		and mouth.y > LIQUID_RECT.position.y - POUR_REACH_ABOVE and mouth.y < LIQUID_RECT.end.y - POUR_INSET


## Starts or stops a carried sack's stream of pellets.
func set_pouring(id : int, pouring : bool) -> void:
	if not pouring or not _carried.has(id):
		_pours.erase(id)
	elif not _pours.has(id):
		_pours[id] = [_carried[id].color, 0.0]


## A handful tipped in at once from a carried sack, like spices.
func drop_handful(id : int, count : int) -> void:
	if not _carried.has(id):
		return
	for i : int in count:
		_spawn_pellet(_carried[id])


func sparkle(color : Color) -> void:
	_sparkles.append([color, SPARKLE_SECONDS])


func clear_pours() -> void:
	_pours.clear()
	_carried.clear()
	_pellets.clear()
	_rings.clear()
	_blooms.clear()
	_trails.clear()
	_sparkles.clear()
	_swirl = 0.0


func _step_pours(delta : float) -> void:
	for id : int in _carried:
		var sack : Dictionary = _carried[id]
		if sack.follow and delta > 0.0:
			var before : Vector2 = sack.at
			sack.at = (sack.at as Vector2).lerp(sack.target, minf(1.0, CARRY_FOLLOW * delta))
			sack.velocity = (sack.at - before) / delta
	for id : int in _pours:
		var pour : Array = _pours[id]
		var sack : Dictionary = _carried[id]
		pour[1] += PELLETS_PER_SECOND * (1.0 + _shake(sack)) * delta
		while pour[1] >= 1.0:
			pour[1] -= 1.0
			_spawn_pellet(sack)
	for i : int in range(_pellets.size() - 1, -1, -1):
		var pellet : Array = _pellets[i]
		pellet[1].y += PELLET_GRAVITY * delta
		pellet[0] += pellet[1] * delta
		if pellet[0].y >= pellet[2]:
			_land(pellet[0], pellet[3], pellet[4])
			_pellets.remove_at(i)
	_swirl_wort(delta)
	# Rings, blooms, stripes and sparkles all keep their seconds left at index 1.
	for list : Array in [_rings, _blooms, _trails, _sparkles]:
		for entry : Array in list:
			entry[1] -= delta
	_rings = _rings.filter(func(ring : Array) -> bool: return ring[1] > 0.0)
	_blooms = _blooms.filter(func(bloom : Array) -> bool: return bloom[1] > 0.0)
	_trails = _trails.filter(func(trail : Array) -> bool: return trail[1] > 0.0)
	_sparkles = _sparkles.filter(func(sparkle_entry : Array) -> bool: return sparkle_entry[1] > 0.0)


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


## The held blade's circling around the middle drives the swirl; it slows on its own,
## but never below the rolling boil's own turn.
func _stir(delta : float) -> void:
	var tip : Vector2 = _paddle.points[0]
	if _dragging and delta > 0.0:
		var place : Vector2 = _to_unit(tip)
		var motion : Vector2 = (_to_unit(tip) - _to_unit(_last_tip)) / delta
		if place.length() > 0.15:
			var circling : float = place.cross(motion) / place.length_squared()
			_swirl = lerpf(_swirl, clampf(circling, -MAX_SWIRL, MAX_SWIRL), minf(1.0, STIR_GAIN * delta))
	_swirl *= exp(-SWIRL_DRAG * delta)
	if bubbling and absf(_swirl) < BOIL_SWIRL:
		var direction : float = signf(_swirl) if _swirl != 0.0 else 1.0
		_swirl = move_toward(_swirl, BOIL_SWIRL * direction, BOIL_SWIRL * delta)
	_last_tip = tip


## Turns the blooms and stripes with the wort; swirling blooms leave stripes.
func _swirl_wort(delta : float) -> void:
	for bloom : Array in _blooms:
		bloom[0] = _turned(bloom[0], delta, 1.0)
	for trail : Array in _trails:
		trail[0] = _turned(trail[0], delta, TRAIL_DRIFT)
	_trail_clock += delta
	if absf(_swirl) < TRAIL_MIN_SWIRL or _trail_clock < TRAIL_INTERVAL:
		return
	_trail_clock = 0.0
	var spread : Vector2 = BLOOM_SIZE / LIQUID_RECT.size * TRAIL_SPREAD
	for bloom : Array in _blooms:
		if _trails.size() >= MAX_TRAILS:
			_trails.pop_front()
		var scatter := Vector2(randf_range(-spread.x, spread.x), randf_range(-spread.y, spread.y))
		_trails.append([bloom[0] + scatter, TRAIL_SECONDS, bloom[2]])


## A place turned by the swirl, faster near the middle; `share` slows it further.
func _turned(place : Vector2, delta : float, share : float) -> Vector2:
	var speed : float = _swirl * lerpf(SWIRL_CENTER_SPEED, 1.0, clampf(place.length(), 0.0, 1.0))
	return place.rotated(speed * share * delta)


func _to_unit(point : Vector2) -> Vector2:
	return (point - LIQUID_RECT.get_center()) / (LIQUID_RECT.size / 2.0)


func _from_unit(place : Vector2) -> Vector2:
	return LIQUID_RECT.get_center() + place * LIQUID_RECT.size / 2.0


## 0 for a sack held still, up to 1 for one shaken hard.
func _shake(sack : Dictionary) -> float:
	return clampf(((sack.velocity as Vector2).length() - SHAKE_FROM) / SHAKE_RANGE, 0.0, 1.0)


## A pellet falls from the sack's mouth into the wort below it; a shaken sack throws
## it off along its own motion, scattered, so it may land anywhere or miss.
func _spawn_pellet(sack : Dictionary) -> void:
	var start : Vector2 = sack.at + LIFTED_SACK_MOUTH * BrewDayArt.PROP_SCALE + Vector2(randf_range(-3, 3), 0)
	var landing : float = LIQUID_RECT.position.y + randf_range(LANDING_DEPTH.x, LANDING_DEPTH.y)
	var shake : float = _shake(sack)
	var throw : Vector2 = (sack.velocity as Vector2) * SHAKE_THROW * shake
	throw += Vector2(randf_range(-1, 1), randf_range(-1, 0.5)) * SHAKE_SCATTER * shake
	var velocity := Vector2(randf_range(-18, 18), randf_range(0, 30)) + throw
	_pellets.append([start, velocity, landing, sack.color, sack.blooms])


func _land(at : Vector2, color : Color, blooms : bool) -> void:
	if not _paddle.inside_mouth(at).is_equal_approx(at):
		return
	_rings.append([at, RING_SECONDS, color])
	if not blooms:
		return
	if _to_unit(at).length() <= BLOOM_REACH:
		if _blooms.size() >= MAX_BLOOMS:
			_blooms.pop_front()
		_blooms.append([_to_unit(at), BLOOM_SECONDS, color])
	liquid_color = liquid_color.lerp(color, WORT_TINT_PER_PELLET)


## Handle first and blade last, as MashSession.paddle_moved expects, in liquid pixels.
func _to_liquid(points : PackedVector2Array) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for i : int in range(points.size() - 1, -1, -1):
		moved.append(points[i] - LIQUID_RECT.position)
	return moved


func _draw() -> void:
	# The liquid and all in it go under the kettle sprite, so its rim hides their edges.
	_fill_ellipse(_ellipse(LIQUID_RECT.grow(LIQUID_UNDER_RIM)), liquid_color)
	_draw_trails()
	_draw_blooms()
	if bubbling:
		_draw_bubbles()
	for clump : MashClump in clumps:
		if not clump.is_broken():
			_draw_clump(clump)
	_draw_bursts()
	if foam > 0.0:
		var foam_size : Vector2 = (LIQUID_RECT.size * clampf(foam, 0.0, 1.0)).round()
		_fill_ellipse(_ellipse(Rect2(LIQUID_RECT.get_center() - foam_size / 2.0, foam_size)), FOAM_COLOR)
	_draw_rings()
	draw_texture_rect(ART.kettle, Rect2(Vector2.ZERO, custom_minimum_size), false)
	if glow_color.a > 0.0:
		var outline : PackedVector2Array = _ellipse(LIQUID_RECT.grow(4))
		outline.append(outline[0])
		draw_polyline(outline, glow_color, 2.0)
	_draw_paddle()
	_draw_pours()


## Blooms spread and step back to the wort's colour, in solid steps, not by fading.
func _draw_blooms() -> void:
	for bloom : Array in _blooms:
		var progress : float = 1.0 - bloom[1] / BLOOM_SECONDS
		var stepped : float = floorf(progress * BLOOM_STEPS) / BLOOM_STEPS
		var color : Color = (bloom[2] as Color).lerp(liquid_color, stepped)
		var bloom_size : Vector2 = (BLOOM_SIZE * lerpf(0.35, 1.0, stepped)).round()
		var rect := Rect2(_from_unit(bloom[0]) - bloom_size / 2.0, bloom_size)
		_fill_ellipse(_ellipse(rect), color)


## Stripe stamps step back to the wort's colour like the blooms do.
func _draw_trails() -> void:
	for trail : Array in _trails:
		var progress : float = 1.0 - trail[1] / TRAIL_SECONDS
		var stepped : float = floorf(progress * TRAIL_STEPS) / TRAIL_STEPS
		var color : Color = (trail[2] as Color).lerp(liquid_color, stepped)
		draw_rect(Rect2((_from_unit(trail[0]) - TRAIL_SIZE / 2.0).round(), TRAIL_SIZE), color)


func _draw_rings() -> void:
	for ring : Array in _rings:
		var progress : float = 1.0 - ring[1] / RING_SECONDS
		var stepped : float = floorf(progress * 3.0 + 1.0) / 3.0
		var ring_size : Vector2 = (RING_SIZE * stepped).round()
		var outline : PackedVector2Array = _ellipse(Rect2(ring[0] - ring_size / 2.0, ring_size))
		outline.append(outline[0])
		draw_polyline(outline, (ring[2] as Color).lightened(0.5), 1.0)


## The carried sacks (jittering while shaken), the falling pellets and the sparkles of
## a perfect addition rising out of the wort.
func _draw_pours() -> void:
	for id : int in _carried:
		var sack : Dictionary = _carried[id]
		var jitter : float = 0.0
		if _shake(sack) > 0.0:
			jitter = 1.0 if int(_clock * ANIMATION_FPS * 2.0) % 2 == 0 else -1.0
		draw_texture_rect(ART.sack_lifted, Rect2(((sack.at as Vector2) + Vector2(jitter, 0)).round(), _lifted_size()), false)
	for pellet : Array in _pellets:
		draw_rect(Rect2((pellet[0] as Vector2).round(), PELLET_SIZE), pellet[3])
	for sparkle_entry : Array in _sparkles:
		var progress : float = 1.0 - sparkle_entry[1] / SPARKLE_SECONDS
		var stepped : float = floorf(progress * 8.0) / 8.0
		for i : int in SPARKLE_DOTS:
			var x : float = LIQUID_RECT.position.x + LIQUID_RECT.size.x * (0.15 + 0.7 * i / float(SPARKLE_DOTS - 1))
			var y : float = LIQUID_RECT.get_center().y - SPARKLE_RISE * stepped * (0.6 + 0.4 * float(i % 3) / 2.0)
			var color : Color = SPARKLE_COLOR if i % 2 == 0 else sparkle_entry[0]
			draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 2)), color)


## Snapped to whole pixels without repeating a point, which would break the fill.
func _lifted_size() -> Vector2:
	return ART.sack_lifted.get_size() * BrewDayArt.PROP_SCALE


func _ellipse(rect : Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i : int in ELLIPSE_POINTS:
		var angle : float = TAU * i / ELLIPSE_POINTS
		var point : Vector2 = (rect.get_center() + Vector2(cos(angle), sin(angle)) * rect.size / 2.0).round()
		if points.is_empty() or not point.is_equal_approx(points[points.size() - 1]):
			points.append(point)
	if points.size() > 1 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	return points


## Fills an ellipse, skipping one too small or thin to have an inside.
func _fill_ellipse(points : PackedVector2Array, color : Color) -> void:
	if points.size() >= 3 and not Geometry2D.triangulate_polygon(points).is_empty():
		draw_colored_polygon(points, color)


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
		var progress : float = 1.0 - burst[1] / BURST_SECONDS
		var stepped : float = floorf(progress * BURST_SECONDS * ANIMATION_FPS * 2.0) / (BURST_SECONDS * ANIMATION_FPS * 2.0)
		for i : int in BURST_DOTS:
			var direction := Vector2.from_angle(TAU * i / BURST_DOTS)
			var at : Vector2 = LIQUID_RECT.position + burst[0] + direction * BURST_REACH * stepped
			draw_rect(Rect2(at.round(), Vector2(2, 2)), CLUMP_LIGHT if i % 2 == 0 else FLASH_COLOR)


## The bent shaft as a polyline; the blade and grip sprites turned along the stick.
func _draw_paddle() -> void:
	var points : PackedVector2Array = _paddle.points
	var shaft : PackedVector2Array = points.slice(PaddleBody.BLADE_SEGMENTS)
	draw_polyline(shaft, PADDLE_SHADE, SHAFT_WIDTH + 2.0)
	draw_polyline(shaft, PADDLE_COLOR, SHAFT_WIDTH)
	var blade_end : Vector2 = points[PaddleBody.BLADE_SEGMENTS]
	_draw_turned(ART.paddle_blade, (points[0] + blade_end) / 2.0, (points[0] - blade_end).angle())
	var last : int = points.size() - 1
	_draw_turned(ART.paddle_grip, points[last], (points[last] - points[last - 1]).angle())


func _draw_turned(texture : Texture2D, center : Vector2, angle : float) -> void:
	draw_set_transform(center.round(), angle, Vector2.ONE * BrewDayArt.PROP_SCALE)
	draw_texture(texture, -texture.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)


func _draw_bubbles() -> void:
	var frame : int = int(_clock * ANIMATION_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, floori(frame / 3.0)))
		var at : Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.9
		draw_rect(Rect2((LIQUID_RECT.get_center() + at * LIQUID_RECT.size / 2.0).round(), Vector2(2, 2)), BUBBLE_COLOR)
