class_name WortSurface
extends RefCounted

## The liquid's surface: the paddle's swirl, hop blooms and the stripes they leave, splash
## rings and perfect-addition sparkles, in the mouth's unit space (KettleShapes).

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
## The blade must be this far out from the middle (unit space) to drive the swirl.
const STIR_FROM : float = 0.15
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
const SPARKLE_SECONDS : float = 0.8
const SPARKLE_DOTS : int = 10
const SPARKLE_RISE : float = 40.0
const SPARKLE_COLOR : Color = Color(1.0, 0.85, 0.3)

## How fast the wort turns, in radians a second; positive is clockwise on screen.
var swirl : float = 0.0

## Each entry is [place or position, seconds left, colour].
var _rings : Array = []
var _blooms : Array = []
var _trails : Array = []
## [colour, seconds left] of each sparkle burst.
var _sparkles : Array = []
var _trail_clock : float = 0.0
var _last_tip : Vector2


func _init(rest_tip : Vector2) -> void:
	_last_tip = rest_tip


func clear() -> void:
	_rings.clear()
	_blooms.clear()
	_trails.clear()
	_sparkles.clear()
	swirl = 0.0


func bloom_count() -> int:
	return _blooms.size()


## The held blade's circling around the middle drives the swirl; it slows on its own,
## but never below the rolling boil's own turn.
func stir(tip : Vector2, held : bool, bubbling : bool, delta : float) -> void:
	if held and delta > 0.0:
		var place : Vector2 = KettleShapes.to_unit(tip)
		var motion : Vector2 = (place - KettleShapes.to_unit(_last_tip)) / delta
		if place.length() > STIR_FROM:
			var circling : float = place.cross(motion) / place.length_squared()
			swirl = lerpf(swirl, clampf(circling, -MAX_SWIRL, MAX_SWIRL), minf(1.0, STIR_GAIN * delta))
	swirl *= exp(-SWIRL_DRAG * delta)
	if bubbling and absf(swirl) < BOIL_SWIRL:
		var direction : float = signf(swirl) if swirl != 0.0 else 1.0
		swirl = move_toward(swirl, BOIL_SWIRL * direction, BOIL_SWIRL * delta)
	_last_tip = tip


## A pellet landed at `at` (kettle pixels): a splash ring, and with `blooms` a bloom
## near the middle. True when it tints the wort.
func land(at : Vector2, color : Color, blooms : bool) -> bool:
	_rings.append([at, RING_SECONDS, color])
	if not blooms:
		return false
	var place : Vector2 = KettleShapes.to_unit(at)
	if place.length() <= BLOOM_REACH:
		if _blooms.size() >= MAX_BLOOMS:
			_blooms.pop_front()
		_blooms.append([place, BLOOM_SECONDS, color])
	return true


func sparkle(color : Color) -> void:
	_sparkles.append([color, SPARKLE_SECONDS])


func step(delta : float) -> void:
	_swirl_wort(delta)
	for list : Array in [_rings, _blooms, _trails, _sparkles]:
		for entry : Array in list:
			entry[1] -= delta
	_rings = _rings.filter(_alive)
	_blooms = _blooms.filter(_alive)
	_trails = _trails.filter(_alive)
	_sparkles = _sparkles.filter(_alive)


## The stripes, then the blooms over them; both step back to the wort's colour.
func draw_under(canvas : CanvasItem, liquid_color : Color) -> void:
	for trail : Array in _trails:
		var faded : float = KettleShapes.stepped(1.0 - trail[1] / TRAIL_SECONDS, TRAIL_STEPS)
		var at : Vector2 = (KettleShapes.from_unit(trail[0]) - TRAIL_SIZE / 2.0).round()
		canvas.draw_rect(Rect2(at, TRAIL_SIZE), (trail[2] as Color).lerp(liquid_color, faded))
	for bloom : Array in _blooms:
		var faded : float = KettleShapes.stepped(1.0 - bloom[1] / BLOOM_SECONDS, BLOOM_STEPS)
		var bloom_size : Vector2 = (BLOOM_SIZE * lerpf(0.35, 1.0, faded)).round()
		var rect := Rect2(KettleShapes.from_unit(bloom[0]) - bloom_size / 2.0, bloom_size)
		KettleShapes.fill_ellipse(canvas, rect, (bloom[2] as Color).lerp(liquid_color, faded))


func draw_rings(canvas : CanvasItem) -> void:
	for ring : Array in _rings:
		var progress : float = 1.0 - ring[1] / RING_SECONDS
		var ring_size : Vector2 = (RING_SIZE * floorf(progress * 3.0 + 1.0) / 3.0).round()
		KettleShapes.outline_ellipse(canvas, Rect2(ring[0] - ring_size / 2.0, ring_size), (ring[2] as Color).lightened(0.5), 1.0)


## Gold and the hop's colour, rising out of the wort in steps.
func draw_sparkles(canvas : CanvasItem) -> void:
	var liquid : Rect2 = KettleView.LIQUID_RECT
	for sparkle_entry : Array in _sparkles:
		var risen : float = KettleShapes.stepped(1.0 - sparkle_entry[1] / SPARKLE_SECONDS, 8.0)
		for i : int in SPARKLE_DOTS:
			var x : float = liquid.position.x + liquid.size.x * (0.15 + 0.7 * i / float(SPARKLE_DOTS - 1))
			var y : float = liquid.get_center().y - SPARKLE_RISE * risen * (0.6 + 0.4 * float(i % 3) / 2.0)
			var color : Color = SPARKLE_COLOR if i % 2 == 0 else sparkle_entry[0]
			canvas.draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 2)), color)


## Turns the blooms and stripes with the wort; swirling blooms leave stripes.
func _swirl_wort(delta : float) -> void:
	for bloom : Array in _blooms:
		bloom[0] = _turned(bloom[0], delta, 1.0)
	for trail : Array in _trails:
		trail[0] = _turned(trail[0], delta, TRAIL_DRIFT)
	_trail_clock += delta
	if absf(swirl) < TRAIL_MIN_SWIRL or _trail_clock < TRAIL_INTERVAL:
		return
	_trail_clock = 0.0
	var spread : Vector2 = BLOOM_SIZE / KettleView.LIQUID_RECT.size * TRAIL_SPREAD
	for bloom : Array in _blooms:
		if _trails.size() >= MAX_TRAILS:
			_trails.pop_front()
		var scatter := Vector2(randf_range(-spread.x, spread.x), randf_range(-spread.y, spread.y))
		_trails.append([bloom[0] + scatter, TRAIL_SECONDS, bloom[2]])


## A place turned by the swirl, faster near the middle; `share` slows it further.
func _turned(place : Vector2, delta : float, share : float) -> Vector2:
	var speed : float = swirl * lerpf(SWIRL_CENTER_SPEED, 1.0, clampf(place.length(), 0.0, 1.0))
	return place.rotated(speed * share * delta)


func _alive(entry : Array) -> bool:
	return entry[1] > 0.0
