class_name KettleView
extends Control

## The brew day's kettle: a round pot seen from the front and a little above (its sprite
## in BrewDayArt), its oval mouth full of liquid,
## the clumps, the foam and the paddle. The paddle is a springy stick (PaddleBody):
## pressing on the liquid puts its blade under the pointer, and the shaft swings around
## over the far rim behind it. The blade breaks the clumps; the shaft only pushes them.
## In the boil a held sack hangs tilted over the mouth and its pellets drop into the
## wort, each landing with a splash ring and a coloured bloom that fades into the wort.
## Stirring sets the wort swirling: the blooms ride the swirl around the kettle and
## leave coloured stripes behind them, and the swirl dies down slowly.

## The stick moved this frame, in liquid pixels (see MashSession.paddle_moved).
signal paddle_moved(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float)
## The paddle hit a kettle wall; speed in pixels a second.
signal paddle_knocked(speed : float)

const ART : BrewDayArt = preload("res://src/resources/brew_day/brew_day_art.tres")
## The bounding box of the oval mouth, the transparent hole in the kettle sprite; the
## liquid is the ellipse inside it.
const LIQUID_RECT : Rect2 = Rect2(Vector2(24, 44), MashSession.LIQUID_SIZE)
const ELLIPSE_POINTS : int = 48
## The blade keeps a little inside the mouth.
const PADDLE_MOUTH : Rect2 = Rect2(LIQUID_RECT.position + Vector2(4, 4), MashSession.LIQUID_SIZE - Vector2(8, 8))
const PADDLE_REST : Vector2 = Vector2(196, 120)
## Grabbing works a little outside the liquid too, at its edge.
const GRAB_MARGIN : float = 10.0
const SHAFT_WIDTH : float = 3.0
const WATER_COLOR : Color = Color(0.36, 0.45, 0.5)
const CLUMP_LIGHT : Color = Color(0.85, 0.72, 0.48)
const FLASH_COLOR : Color = Color(1, 0.97, 0.85)
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
## Where lifted sacks hang over the mouth, one spot per sack pouring at once.
const POUR_SPOTS : Array[Vector2] = [Vector2(78, 4), Vector2(170, 4), Vector2(124, -4)]
## Where the lifted sack sprite's mouth is, for the falling pellets.
const LIFTED_SACK_MOUTH : Vector2 = Vector2(27, 33)
const PELLETS_PER_SECOND : float = 30.0
const PELLET_GRAVITY : float = 420.0
const PELLET_SIZE : Vector2 = Vector2(2, 2)
## Pellets land this far into the mouth from its top edge.
const LANDING_DEPTH : Vector2 = Vector2(18, 62)
const RING_SECONDS : float = 0.45
const RING_SIZE : Vector2 = Vector2(18, 8)
const BLOOM_SECONDS : float = 6.0
const BLOOM_SIZE : Vector2 = Vector2(40, 18)
## Colour steps a bloom takes back to the wort's colour, instead of fading.
const BLOOM_STEPS : int = 6
const MAX_BLOOMS : int = 20
## Blooms land this far from the middle at most (share of the mouth), so they stay
## inside it all the way round a swirl.
const BLOOM_REACH : float = 0.62
## How quickly the wort takes up the paddle's circling, and how slowly it lets go.
const STIR_GAIN : float = 3.0
const SWIRL_DRAG : float = 0.35
const MAX_SWIRL : float = 4.0
## A swirling bloom drops a stripe stamp this often, once the swirl is this fast.
const TRAIL_INTERVAL : float = 0.04
const TRAIL_MIN_SWIRL : float = 0.3
const TRAIL_SECONDS : float = 5.0
const TRAIL_STEPS : int = 5
const TRAIL_SIZE : Vector2 = Vector2(4, 2)
const MAX_TRAILS : int = 320
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
## [position, velocity, landing y, colour] of each falling pellet.
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
	custom_minimum_size = ART.kettle.get_size()
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
	clear_pours()


func flash_clump(clump : MashClump) -> void:
	_flashes[clump] = FLASH_SECONDS


func burst_clump(clump : MashClump) -> void:
	_flashes.erase(clump)
	_bursts.append([clump.position, BURST_SECONDS])


## Starts or stops a sack pouring over the mouth; pellets keep coming while it pours.
func set_pouring(id : int, pouring : bool, color : Color) -> void:
	if not pouring:
		_pours.erase(id)
	elif not _pours.has(id):
		_pours[id] = [color, 0.0]


func is_pouring(id : int) -> bool:
	return _pours.has(id)


## A handful dropped at once, like spices tipped in.
func drop_handful(color : Color, count : int) -> void:
	for i : int in count:
		_spawn_pellet(_pour_spot(_pours.size()), color)


func sparkle(color : Color) -> void:
	_sparkles.append([color, SPARKLE_SECONDS])


func clear_pours() -> void:
	_pours.clear()
	_pellets.clear()
	_rings.clear()
	_blooms.clear()
	_trails.clear()
	_sparkles.clear()
	_swirl = 0.0


func _pour_spot(index : int) -> Vector2:
	return POUR_SPOTS[index % POUR_SPOTS.size()]


func _step_pours(delta : float) -> void:
	var index : int = 0
	for id : int in _pours:
		var pour : Array = _pours[id]
		pour[1] += PELLETS_PER_SECOND * delta
		while pour[1] >= 1.0:
			pour[1] -= 1.0
			_spawn_pellet(_pour_spot(index), pour[0])
		index += 1
	for i : int in range(_pellets.size() - 1, -1, -1):
		var pellet : Array = _pellets[i]
		pellet[1].y += PELLET_GRAVITY * delta
		pellet[0] += pellet[1] * delta
		if pellet[0].y >= pellet[2]:
			_land(pellet[0], pellet[3])
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


## The held blade's circling around the middle drives the swirl; it slows on its own.
func _stir(delta : float) -> void:
	var tip : Vector2 = _paddle.points[0]
	if _dragging and delta > 0.0:
		var place : Vector2 = _to_unit(tip)
		var motion : Vector2 = (_to_unit(tip) - _to_unit(_last_tip)) / delta
		if place.length() > 0.15:
			var circling : float = place.cross(motion) / place.length_squared()
			_swirl = lerpf(_swirl, clampf(circling, -MAX_SWIRL, MAX_SWIRL), minf(1.0, STIR_GAIN * delta))
	_swirl *= exp(-SWIRL_DRAG * delta)
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


## A pellet falls from the sack's mouth to a spot in the wort below it.
func _spawn_pellet(spot : Vector2, color : Color) -> void:
	var start : Vector2 = spot + LIFTED_SACK_MOUTH
	var landing : float = LIQUID_RECT.position.y + randf_range(LANDING_DEPTH.x, LANDING_DEPTH.y)
	_pellets.append([start + Vector2(randf_range(-3, 3), 0), Vector2(randf_range(-18, 18), randf_range(0, 30)), landing, color])


func _land(at : Vector2, color : Color) -> void:
	if not _paddle.inside_mouth(at).is_equal_approx(at):
		return
	_rings.append([at, RING_SECONDS, color])
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
	draw_texture(ART.kettle, Vector2.ZERO)
	_fill_ellipse(_ellipse(LIQUID_RECT), liquid_color)
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
	if glow_color.a > 0.0:
		var outline : PackedVector2Array = _ellipse(LIQUID_RECT.grow(4))
		outline.append(outline[0])
		draw_polyline(outline, glow_color, 2.0)
	_draw_rings()
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


## The lifted sacks tilted over the mouth, the falling pellets and the sparkles of a
## perfect addition rising out of the wort.
func _draw_pours() -> void:
	for index : int in _pours.size():
		draw_texture(ART.sack_lifted, _pour_spot(index))
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
	var at : Vector2 = (LIQUID_RECT.position + clump.position - frame_size / 2.0).round()
	var hit : bool = clump.swipes_left < MashSession.SWIPES_PER_CLUMP
	var flashing : bool = _flashes.has(clump)
	if flashing:
		var shake : int = int(_clock * ANIMATION_FPS * 2.0)
		at.x += 1.0 if shake % 2 == 0 else -1.0
	var region := Rect2(Vector2(frame_size.x if hit else 0.0, 0.0), frame_size)
	draw_texture_rect_region(ART.clump, Rect2(at, frame_size), region, FLASH_MODULATE if flashing else Color.WHITE)


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
	draw_set_transform(center.round(), angle)
	draw_texture(texture, -texture.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)


func _draw_bubbles() -> void:
	var frame : int = int(_clock * ANIMATION_FPS)
	var rng := RandomNumberGenerator.new()
	for i : int in BUBBLE_COUNT:
		rng.seed = hash(Vector2i(i, floori(frame / 3.0)))
		var at : Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.9
		draw_rect(Rect2((LIQUID_RECT.get_center() + at * LIQUID_RECT.size / 2.0).round(), Vector2(2, 2)), BUBBLE_COLOR)
