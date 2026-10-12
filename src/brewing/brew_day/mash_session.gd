class_name MashSession
extends RefCounted

## The mash: heat the water to the malt marker, add the malts (the temperature drops),
## then hold each step's temperature for its counted seconds. The clock starts with the
## malts and pauses while ramping to the next step. Clumps appear with the malts and a
## few more later; any left at the end cut the score.

signal malts_added()
signal step_reached(index : int)
signal step_completed(index : int)
signal mash_completed()
signal clump_appeared(clump : MashClump)
signal clump_swiped(clump : MashClump)
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
const SWIPES_PER_CLUMP : int = 2
## The liquid seen from above, in pixels; clumps and the paddle live in this space.
const LIQUID_SIZE : Vector2 = Vector2(232, 104)
const CLUMP_RADIUS : float = 11.0
## Clumps keep this far from the liquid's edges.
const CLUMP_MARGIN : Vector2 = Vector2(24, 18)
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
	match phase:
		Phase.HOLD:
			_hold(delta)
		Phase.RAMP:
			if heat.temperature >= steps[step_index] - STEP_REACHED_MARGIN:
				phase = Phase.HOLD
				step_elapsed = 0.0
				_was_in_band = is_in_band()
				step_reached.emit(step_index)


## The paddle's blade is the segment from `from` to `to` (liquid pixels); sweeping it
## into a clump and out again swipes it.
func paddle_swept(from : Vector2, to : Vector2) -> void:
	for clump : MashClump in clumps:
		if clump.is_broken():
			continue
		var closest : Vector2 = Geometry2D.get_closest_point_to_segment(clump.position, from, to)
		var inside : bool = closest.distance_to(clump.position) <= CLUMP_RADIUS
		if clump.paddle_inside and not inside:
			clump.swipes_left -= 1
			clump_swiped.emit(clump)
			if clump.is_broken():
				clump_broken.emit(clump)
		clump.paddle_inside = inside


## The paddle touching one point only.
func paddle_at(at : Vector2) -> void:
	paddle_swept(at, at)


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


func _spawn_clump() -> void:
	var at : Vector2 = Vector2.ZERO
	for attempt : int in 12:
		at = Vector2(_rng.randf_range(CLUMP_MARGIN.x, LIQUID_SIZE.x - CLUMP_MARGIN.x), _rng.randf_range(CLUMP_MARGIN.y, LIQUID_SIZE.y - CLUMP_MARGIN.y)).round()
		if clumps.all(func(clump : MashClump) -> bool: return clump.is_broken() or clump.position.distance_to(at) >= CLUMP_MIN_GAP):
			break
	var clump := MashClump.new(at, SWIPES_PER_CLUMP)
	clumps.append(clump)
	clump_appeared.emit(clump)
