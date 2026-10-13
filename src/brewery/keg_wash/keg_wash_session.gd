class_name KegWashSession
extends RefCounted

## Washing one dirty keg. The brush scrubs dirt loose (and knocks out the hat and the
## coconut, and shoos the critters), the hose rinses loose dirt away, and the sanitizer
## covers the inside, though never over dirt still there. The keg is done when it is
## spotless and fully covered; cleanliness() scores a wash stopped before that.

signal spot_loosened(spot : KegWashSpot)
signal spot_removed(spot : KegWashSpot)
signal critter_fled(spot : KegWashSpot)
signal mistake(kind : Mistake)
signal completed()

## Wrong moves the window answers with a humour line.
enum Mistake {
	## Hosing dirt that has not been scrubbed loose.
	WASTED_WATER,
	## Scrubbing a keg with no stuck dirt left.
	POLISHING,
	## Spraying a patch that is already fully sanitized.
	GERMS_DEAD,
}

var spots : Array[KegWashSpot] = []
## Centres of the coverage cells inside the opening, and each one's coverage 0..1.
var cells : PackedVector2Array = PackedVector2Array()
var cell_coverage : PackedFloat32Array = PackedFloat32Array()
var is_completed : bool = false


func _init(keg_spots : Array[KegWashSpot]) -> void:
	spots = keg_spots
	_build_cells()


static func create(rng : RandomNumberGenerator) -> KegWashSession:
	return KegWashSession.new(KegWashRules.roll_spots(rng))


## The brush moved from `from` to `to` while held down, over `delta` seconds.
func scrub(from : Vector2, to : Vector2, delta : float) -> void:
	if is_completed or delta <= 0.0:
		return
	var length : float = from.distance_to(to)
	var speed : float = length / delta
	var touched_stuck : bool = false
	for spot : KegWashSpot in spots:
		var distance : float = Geometry2D.get_closest_point_to_segment(spot.position, from, to).distance_to(spot.position)
		if KegWashRules.is_critter(spot.kind):
			if spot.state == KegWashSpot.State.STUCK and distance <= KegWashRules.FLEE_RADIUS:
				spot.state = KegWashSpot.State.FLEEING
				spot.flee_left = KegWashRules.FLEE_SECONDS[spot.kind]
				critter_fled.emit(spot)
			continue
		if spot.state != KegWashSpot.State.STUCK or distance > KegWashRules.BRUSH_RADIUS + KegWashRules.SPOT_RADIUS:
			continue
		touched_stuck = true
		spot.work += KegWashRules.scrub_work(spot.kind, length, speed)
		if spot.work >= KegWashRules.WORK[spot.kind]:
			_loosen(spot)
	if not touched_stuck and speed >= KegWashRules.MIN_SCRUB_SPEED and stuck_count() == 0:
		mistake.emit(Mistake.POLISHING)
	_check_completed()


## The hose's water hit `at` for `delta` seconds.
func rinse(at : Vector2, delta : float) -> void:
	if is_completed:
		return
	for spot : KegWashSpot in spots:
		if spot.position.distance_to(at) > KegWashRules.HOSE_RADIUS + KegWashRules.SPOT_RADIUS:
			continue
		if spot.state == KegWashSpot.State.LOOSE:
			spot.rinsed += delta
			if spot.rinsed >= KegWashRules.RINSE_SECONDS:
				_remove(spot)
		elif spot.state == KegWashSpot.State.STUCK and not KegWashRules.is_critter(spot.kind):
			mistake.emit(Mistake.WASTED_WATER)
	_check_completed()


## The sanitizer's mist hit `at` for `delta` seconds. It does not stick to dirt.
func sanitize(at : Vector2, delta : float) -> void:
	if is_completed:
		return
	var hit_any : bool = false
	var all_done : bool = true
	for i : int in cells.size():
		if cells[i].distance_to(at) > KegWashRules.SPRAY_RADIUS or _under_dirt(cells[i]):
			continue
		hit_any = true
		all_done = all_done and cell_coverage[i] >= 1.0
		cell_coverage[i] = minf(1.0, cell_coverage[i] + KegWashRules.SPRAY_RATE * delta)
	if hit_any and all_done:
		mistake.emit(Mistake.GERMS_DEAD)
	_check_completed()


## Fleeing critters leave after their moment.
func update(delta : float) -> void:
	for spot : KegWashSpot in spots:
		if spot.state == KegWashSpot.State.FLEEING:
			spot.flee_left -= delta
			if spot.flee_left <= 0.0:
				_remove(spot)
	_check_completed()


func stuck_count() -> int:
	return spots.filter(func(spot : KegWashSpot) -> bool: return spot.state == KegWashSpot.State.STUCK and not KegWashRules.is_critter(spot.kind)).size()


func coverage() -> float:
	if cells.is_empty():
		return 1.0
	var total : float = 0.0
	for value : float in cell_coverage:
		total += value
	return total / cells.size()


func is_spotless() -> bool:
	return spots.all(func(spot : KegWashSpot) -> bool: return spot.is_gone())


## 0 to 1: how much of the dirt is scrubbed loose, how much is gone, how much is covered.
func cleanliness() -> float:
	if is_completed:
		return KegRules.CLEAN
	if spots.is_empty():
		return KegWashRules.cleanliness(1.0, 1.0, coverage())
	var scrubbed : int = spots.filter(func(spot : KegWashSpot) -> bool: return spot.state != KegWashSpot.State.STUCK).size()
	var gone : int = spots.filter(func(spot : KegWashSpot) -> bool: return spot.is_gone()).size()
	return KegWashRules.cleanliness(float(scrubbed) / spots.size(), float(gone) / spots.size(), coverage())


func _loosen(spot : KegWashSpot) -> void:
	if KegWashRules.pops_out(spot.kind):
		_remove(spot)
		return
	spot.state = KegWashSpot.State.LOOSE
	spot_loosened.emit(spot)


func _remove(spot : KegWashSpot) -> void:
	spot.state = KegWashSpot.State.GONE
	spot_removed.emit(spot)


func _under_dirt(point : Vector2) -> bool:
	for spot : KegWashSpot in spots:
		if not spot.is_gone() and spot.position.distance_to(point) <= KegWashRules.SPOT_RADIUS + KegWashRules.COVERAGE_CELL / 2.0:
			return true
	return false


func _check_completed() -> void:
	if is_completed or not is_spotless() or coverage() < KegWashRules.FULL_COVERAGE:
		return
	is_completed = true
	completed.emit()


func _build_cells() -> void:
	var half : Vector2 = KegTunnel.OPENING_RADII
	var start : Vector2 = KegTunnel.OPENING_CENTER - half
	var step : float = KegWashRules.COVERAGE_CELL
	var y : float = start.y + step / 2.0
	while y < start.y + half.y * 2.0:
		var x : float = start.x + step / 2.0
		while x < start.x + half.x * 2.0:
			var point : Vector2 = Vector2(x, y)
			if KegTunnel.reach(point) <= 0.95:
				cells.append(point)
			x += step
		y += step
	cell_coverage.resize(cells.size())
	cell_coverage.fill(0.0)
