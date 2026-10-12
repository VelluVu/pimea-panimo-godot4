class_name MashSession
extends RefCounted

## The mash: heat the water to the malt marker, add the malts (the temperature drops),
## then hold each step's temperature for its counted seconds. The clock starts with the
## malts and pauses while ramping to the next step. Clumps appear with the malts and a
## few more later; any left at the end cut the score. A clump breaks after a few hard
## blows of the paddle's blade; each knocks it away, the shaft or a slow push only
## carries it along, and the mash slowly swirls them around.

signal malts_added()
signal step_reached(index : int)
signal step_completed(index : int)
signal mash_completed()
signal clump_appeared(clump : MashClump)
signal clump_swiped(clump : MashClump)
## A clump hit the kettle wall hard enough to be heard.
signal clump_bounced(clump : MashClump)
signal clump_broken(clump : MashClump)
signal band_left(too_hot : bool)
signal band_entered()

enum Phase { WATER, HOLD, RAMP, DONE }

const MALT_DROP : float = 3.0
## The water starts this far under the malt marker.
const START_BELOW_MARKER : float = 10.0
const HEAT_RATE : float = 4.0
const LOSS_RATE : float = 0.3
const BURNER_LAG : float = 0.35
const BAND : float = 2.0
const CLUMPS_AT_DOUGH_IN : int = 3
const WHEAT_EXTRA_CLUMPS : int = 2
const LATE_CLUMPS_MIN : int = 1
const LATE_CLUMPS_MAX : int = 2
const LATE_CLUMP_EARLIEST : float = 2.0
const LATE_CLUMP_LATEST : float = 8.0
const SWIPES_PER_CLUMP : int = 3
## A blade slower than this (liquid pixels a second) only pushes a clump along.
const MIN_SWIPE_SPEED : float = 280.0
## In-between stick positions checked per frame, so a fast whip cannot skip a clump.
const SWEEP_SAMPLES : int = 4
## Clump speeds in liquid pixels a second.
const MAX_KNOCK_SPEED : float = 170.0
const MAX_PUSH_SPEED : float = 60.0
const CLUMP_DRAG : float = 2.5
const SWIRL_ACCEL : float = 15.0
const WALL_BOUNCE : float = 0.55
const BOUNCE_SOUND_SPEED : float = 60.0
## One swing can only hit a clump once.
const HIT_COOLDOWN : float = 0.15
## The kettle mouth's bounding box in pixels; the liquid is the ellipse inside it.
## Clumps and the paddle live in this space.
const LIQUID_SIZE : Vector2 = Vector2(232, 104)
const CLUMP_RADIUS : float = 11.0
## New clumps appear within this share of the ellipse, away from its rim.
const SPAWN_REACH : float = 0.75
const CLUMP_PENALTY : float = 0.06
const CLUMP_MIN_GAP : float = 40.0
## Each step is entered once it is this close below its temperature.
const STEP_REACHED_MARGIN : float = 0.5

var steps : Array[float] = []
var step_seconds : Array[float] = []
var band : float = BAND
var heat : KettleHeat
var phase : Phase = Phase.WATER
var step_index : int = 0
var step_elapsed : float = 0.0
var counted : float = 0.0
var in_band_time : float = 0.0
var clumps : Array[MashClump] = []

var _dough_in_clumps : int = CLUMPS_AT_DOUGH_IN
var _late_clump_times : Array[float] = []
var _rng : RandomNumberGenerator
var _was_in_band : bool = true


func _init(step_temperatures : Array[float], band_width : float = BAND, burner_lag : float = BURNER_LAG, dough_in_clumps : int = CLUMPS_AT_DOUGH_IN, rng : RandomNumberGenerator = null) -> void:
	steps = step_temperatures.duplicate()
	if steps.is_empty():
		steps.append(65.0)
	step_seconds = MashProgram.step_seconds(steps.size())
	band = band_width
	_dough_in_clumps = dough_in_clumps
	_rng = rng if rng != null else RandomNumberGenerator.new()
	heat = KettleHeat.new(malt_marker() - START_BELOW_MARKER, HEAT_RATE, LOSS_RATE, burner_lag)


## The water temperature to add the malts at: they cool it to the first step.
func malt_marker() -> float:
	return steps[0] + MALT_DROP


func target() -> float:
	return malt_marker() if phase == Phase.WATER else steps[step_index]


func is_in_band() -> bool:
	return absf(heat.temperature - target()) <= band


func is_counting() -> bool:
	return phase == Phase.HOLD


func set_heating(on : bool) -> void:
	heat.heating = on


func add_malts() -> void:
	if phase != Phase.WATER:
		return
	heat.temperature -= MALT_DROP
	phase = Phase.HOLD
	malts_added.emit()
	for i : int in _dough_in_clumps:
		_spawn_clump()
	for i : int in _rng.randi_range(LATE_CLUMPS_MIN, LATE_CLUMPS_MAX):
		_late_clump_times.append(_rng.randf_range(LATE_CLUMP_EARLIEST, LATE_CLUMP_LATEST))
	_was_in_band = is_in_band()


func step(delta : float) -> void:
	if phase == Phase.DONE:
		return
	heat.step(delta)
	if phase != Phase.WATER:
		_move_clumps(delta)
	match phase:
		Phase.HOLD:
			_hold(delta)
		Phase.RAMP:
			if heat.temperature >= steps[step_index] - STEP_REACHED_MARGIN:
				phase = Phase.HOLD
				step_elapsed = 0.0
				_was_in_band = is_in_band()
				step_reached.emit(step_index)


## The paddle moved from `before` to `after` in `delta` seconds: two polylines of the
## same points in liquid pixels, handle first. Segments from index `blade_from` on are
## the blade. A clump the moving stick touches is hit if the blade there was fast
## enough, otherwise pushed along at the stick's speed.
func paddle_moved(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float) -> void:
	if delta <= 0.0 or before.size() != after.size() or after.size() < 2:
		return
	for clump : MashClump in clumps:
		if clump.is_broken() or clump.cooldown > 0.0:
			continue
		for sample : int in range(1, SWEEP_SAMPLES + 1):
			if _touch(clump, before, after, float(sample) / SWEEP_SAMPLES, blade_from, delta):
				break


func _touch(clump : MashClump, before : PackedVector2Array, after : PackedVector2Array, progress : float, blade_from : int, delta : float) -> bool:
	for k : int in after.size() - 1:
		var a : Vector2 = before[k].lerp(after[k], progress)
		var b : Vector2 = before[k + 1].lerp(after[k + 1], progress)
		var closest : Vector2 = Geometry2D.get_closest_point_to_segment(clump.position, a, b)
		# The shaft above the mash does not touch it.
		if closest.distance_to(clump.position) > CLUMP_RADIUS or not is_in_liquid(closest):
			continue
		var along : float = 0.0 if a.is_equal_approx(b) else a.distance_to(closest) / a.distance_to(b)
		var velocity : Vector2 = (after[k] - before[k]).lerp(after[k + 1] - before[k + 1], along) / delta
		_strike(clump, velocity, k >= blade_from)
		return true
	return false


func _strike(clump : MashClump, velocity : Vector2, on_blade : bool) -> void:
	if not on_blade or velocity.length() < MIN_SWIPE_SPEED:
		clump.velocity = velocity.limit_length(MAX_PUSH_SPEED)
		return
	clump.velocity = velocity.limit_length(MAX_KNOCK_SPEED)
	clump.cooldown = HIT_COOLDOWN
	clump.swipes_left -= 1
	clump_swiped.emit(clump)
	if clump.is_broken():
		clump_broken.emit(clump)


func clumps_left() -> int:
	return clumps.filter(func(clump : MashClump) -> bool: return not clump.is_broken()).size()


## Share of the counted time so far spent in the band, for the live readout.
func accuracy() -> float:
	return in_band_time / counted if counted > 0.0 else 1.0


func score() -> float:
	return clampf(in_band_time / MashProgram.MASH_SECONDS - clumps_left() * CLUMP_PENALTY, 0.0, 1.0)


func _hold(delta : float) -> void:
	counted += delta
	step_elapsed += delta
	var in_band : bool = is_in_band()
	if in_band:
		in_band_time += delta
	if in_band != _was_in_band:
		if in_band:
			band_entered.emit()
		else:
			band_left.emit(heat.temperature > target())
		_was_in_band = in_band
	for i : int in range(_late_clump_times.size() - 1, -1, -1):
		if counted >= _late_clump_times[i]:
			_late_clump_times.remove_at(i)
			_spawn_clump()
	if step_elapsed >= step_seconds[step_index]:
		step_completed.emit(step_index)
		if step_index == steps.size() - 1:
			phase = Phase.DONE
			mash_completed.emit()
		else:
			step_index += 1
			phase = Phase.RAMP


## True inside the liquid's ellipse.
static func is_in_liquid(point : Vector2) -> bool:
	return ((point - LIQUID_SIZE / 2.0) / (LIQUID_SIZE / 2.0)).length() <= 1.0


## The mash swirls the clumps slowly around its middle; knocks fade with the drag and
## the kettle wall bounces them back.
func _move_clumps(delta : float) -> void:
	var middle : Vector2 = LIQUID_SIZE / 2.0
	var half : Vector2 = middle - Vector2(CLUMP_RADIUS, CLUMP_RADIUS)
	for clump : MashClump in clumps:
		if clump.is_broken():
			continue
		clump.cooldown = maxf(0.0, clump.cooldown - delta)
		var from_middle : Vector2 = clump.position - middle
		if from_middle.length() > 1.0:
			clump.velocity += Vector2(-from_middle.y, from_middle.x).normalized() * SWIRL_ACCEL * delta
		clump.velocity *= exp(-CLUMP_DRAG * delta)
		clump.position += clump.velocity * delta
		var scaled : Vector2 = (clump.position - middle) / half
		if scaled.length() <= 1.0:
			continue
		clump.position = middle + scaled.normalized() * half
		# The ellipse's outward normal at that point.
		var normal : Vector2 = ((clump.position - middle) / (half * half)).normalized()
		var into_wall : float = clump.velocity.dot(normal)
		if into_wall > 0.0:
			if into_wall >= BOUNCE_SOUND_SPEED:
				clump_bounced.emit(clump)
			clump.velocity -= normal * into_wall * (1.0 + WALL_BOUNCE)


func _spawn_clump() -> void:
	var at : Vector2 = Vector2.ZERO
	for attempt : int in 12:
		var spot : Vector2 = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * SPAWN_REACH
		at = (LIQUID_SIZE / 2.0 + spot * LIQUID_SIZE / 2.0).round()
		if clumps.all(func(clump : MashClump) -> bool: return clump.is_broken() or clump.position.distance_to(at) >= CLUMP_MIN_GAP):
			break
	var clump := MashClump.new(at, SWIPES_PER_CLUMP)
	clumps.append(clump)
	clump_appeared.emit(clump)
