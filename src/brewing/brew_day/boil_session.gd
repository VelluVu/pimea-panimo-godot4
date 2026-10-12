class_name BoilSession
extends RefCounted

## The boil: heat to a rolling boil and keep it there for the counted seconds while
## pouring the hop additions on their marks. Under BOIL_MIN the boil stops and so does
## the clock; over FOAM_FROM the foam rises, and a full kettle boils over. The hot break
## and every hop pour make it foam harder, as they do in a real kettle.
## Hold a sack to pour; the pour is judged on release: started in its window and within
## the gram tolerance is a full hit, one of the two a half, neither a miss.

signal boil_started()
signal boil_stopped()
signal boil_resumed()
signal boiled_over()
signal mark_resolved(mark : BoilMark)
signal stray_pour(ingredient_id : int)
signal boil_completed()

enum Phase { RAMP, BOILING, DONE }

const START_TEMPERATURE : float = 92.0
const HEAT_RATE : float = 4.0
const LOSS_RATE : float = 1.0
const BOIL_MIN : float = 98.0
const FOAM_FROM : float = 102.0
const FOAM_RISE_PER_DEGREE : float = 0.35
const FOAM_FALL : float = 0.4
const HOT_BREAK_SECONDS : float = 2.0
const HOT_BREAK_FOAM_FACTOR : float = 1.8
const HOP_SURGE : float = 0.15
const FOAM_AFTER_BOIL_OVER : float = 0.3
const BOIL_OVER_COOLING : float = 2.0
const BOIL_OVER_PENALTY : float = 0.25
const GRAM_TOLERANCE : float = 0.1
## A pour lasts about this long when it hits its mark's grams.
const POUR_SECONDS_AT_TARGET : float = 1.2
const DEFAULT_POUR_RATE : float = 25.0

var heat : KettleHeat
var phase : Phase = Phase.RAMP
var counted : float = 0.0
var in_band_time : float = 0.0
var foam : float = 0.0
var boil_overs : int = 0
var marks : Array[BoilMark] = []
## Ingredient id -> grams (or pieces) still in the sack.
var sacks : Dictionary = {}
var gram_tolerance : float = GRAM_TOLERANCE
var window_widen : float = 0.0

var _piece_ids : Array[int] = []
var _pours : Dictionary = {}
var _boiling : bool = false


## `piece_ids` are tapped in whole (spices) instead of poured by weight.
func _init(boil_marks : Array[BoilMark], piece_ids : Array[int] = [], burner_lag : float = MashSession.BURNER_LAG) -> void:
	for mark : BoilMark in boil_marks:
		if not BoilSchedule.is_in_boil(mark.kind):
			continue
		marks.append(mark)
		sacks[mark.ingredient_id] = float(sacks.get(mark.ingredient_id, 0.0)) + mark.grams
	_piece_ids = piece_ids.duplicate()
	heat = KettleHeat.new(START_TEMPERATURE, HEAT_RATE, LOSS_RATE, burner_lag)


func set_heating(on : bool) -> void:
	heat.heating = on


func is_boiling() -> bool:
	return heat.temperature >= BOIL_MIN


func is_in_band() -> bool:
	return heat.temperature >= BOIL_MIN and heat.temperature <= FOAM_FROM


func is_pouring(id : int) -> bool:
	return _pours.has(id)


func step(delta : float) -> void:
	if phase == Phase.DONE:
		return
	heat.step(delta)
	_step_foam(delta)
	for id : int in _pours:
		var pour : Dictionary = _pours[id]
		var grams : float = minf(pour.rate * delta, sacks[id])
		sacks[id] -= grams
		pour.grams += grams
	if phase == Phase.RAMP:
		if is_boiling():
			phase = Phase.BOILING
			_boiling = true
			boil_started.emit()
		return
	if is_boiling() != _boiling:
		_boiling = is_boiling()
		if _boiling:
			boil_resumed.emit()
		else:
			boil_stopped.emit()
	if not _boiling:
		return
	counted += delta
	if is_in_band():
		in_band_time += delta
	for mark : BoilMark in marks:
		if mark.is_open() and counted > BoilSchedule.window_end(mark.kind, window_widen) + BoilSchedule.NEAR_MISS:
			_resolve(mark, BoilMark.Result.MISS)
	if counted >= BoilSchedule.end_time() and _pours.is_empty():
		_finish()


func start_pour(id : int) -> void:
	if phase == Phase.DONE or _pours.has(id) or float(sacks.get(id, 0.0)) <= 0.0:
		return
	var own : BoilMark = _nearest_open_mark(id)
	# Before the boil starts every pour is early.
	var timed : bool = phase == Phase.BOILING and own != null and BoilSchedule.in_window(own.kind, counted, window_widen)
	var other : BoilMark = null
	if own == null and phase == Phase.BOILING:
		other = _open_mark_in_window()
	if not _piece_ids.has(id):
		foam += HOP_SURGE
	if _piece_ids.has(id):
		var pieces : float = own.grams if own != null else sacks[id]
		sacks[id] = maxf(0.0, sacks[id] - pieces)
		_judge(own, timed, true, other, id)
		return
	var aimed : BoilMark = own if own != null else other
	var target : float = float(aimed.grams) if aimed != null else 0.0
	var rate : float = target / POUR_SECONDS_AT_TARGET if target > 0.0 else DEFAULT_POUR_RATE
	_pours[id] = {"rate": rate, "grams": 0.0, "own": own, "timed": timed, "other": other}


func stop_pour(id : int) -> void:
	if not _pours.has(id):
		return
	var pour : Dictionary = _pours[id]
	_pours.erase(id)
	var own : BoilMark = pour.own
	var amount_right : bool = own != null and absf(pour.grams - own.grams) <= own.grams * gram_tolerance
	_judge(own, pour.timed, amount_right, pour.other, id)
	if phase == Phase.BOILING and counted >= BoilSchedule.end_time() and _pours.is_empty():
		_finish()


## Hop timing and boil control weigh the same; a boil with no marks is all control.
func score() -> float:
	var control : float = clampf(in_band_time / maxf(counted, 0.001) - boil_overs * BOIL_OVER_PENALTY, 0.0, 1.0)
	if marks.is_empty():
		return control
	var points : float = 0.0
	for mark : BoilMark in marks:
		points += mark.points()
	return 0.5 * control + 0.5 * points / marks.size()


## Marks still waiting, for the view's list.
func open_marks() -> Array[BoilMark]:
	return marks.filter(func(mark : BoilMark) -> bool: return mark.is_open())


func _step_foam(delta : float) -> void:
	if heat.temperature > FOAM_FROM:
		var rise : float = (heat.temperature - FOAM_FROM) * FOAM_RISE_PER_DEGREE
		if _boiling and counted < HOT_BREAK_SECONDS:
			rise *= HOT_BREAK_FOAM_FACTOR
		foam += rise * delta
	else:
		foam = maxf(0.0, foam - FOAM_FALL * delta)
	if foam >= 1.0:
		boil_overs += 1
		foam = FOAM_AFTER_BOIL_OVER
		heat.temperature -= BOIL_OVER_COOLING
		boiled_over.emit()


func _judge(own : BoilMark, timed : bool, amount_right : bool, other : BoilMark, id : int) -> void:
	if own != null:
		if timed and amount_right:
			_resolve(own, BoilMark.Result.HALF if own.bittering_only else BoilMark.Result.FULL)
		elif timed or amount_right:
			_resolve(own, BoilMark.Result.HALF)
		else:
			_resolve(own, BoilMark.Result.MISS)
	elif other != null and other.is_open():
		_resolve(other, BoilMark.Result.HALF)
	else:
		stray_pour.emit(id)


## The sack's open mark closest in time, if the pour is near enough to count as a try.
func _nearest_open_mark(id : int) -> BoilMark:
	var best : BoilMark = null
	for mark : BoilMark in marks:
		if not mark.is_open() or mark.ingredient_id != id:
			continue
		var start : float = BoilSchedule.window_start(mark.kind, window_widen) - BoilSchedule.NEAR_MISS
		var end : float = BoilSchedule.window_end(mark.kind, window_widen) + BoilSchedule.NEAR_MISS
		if counted < start or counted > end:
			continue
		if best == null or absf(mark.time - counted) < absf(best.time - counted):
			best = mark
	return best


func _open_mark_in_window() -> BoilMark:
	for mark : BoilMark in marks:
		if mark.is_open() and BoilSchedule.in_window(mark.kind, counted, window_widen):
			return mark
	return null


func _resolve(mark : BoilMark, result : BoilMark.Result) -> void:
	mark.result = result
	mark_resolved.emit(mark)


func _finish() -> void:
	for mark : BoilMark in marks:
		if mark.is_open():
			_resolve(mark, BoilMark.Result.MISS)
	phase = Phase.DONE
	boil_completed.emit()
