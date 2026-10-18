class_name HoseRope
extends RefCounted

## The keg wash hose as a sagging rope of points: fixed at the tap, the nozzle pinned where
## the hand or hook holds it, never pulled past its length.

## Long enough to reach the far side of the keg from the tap, with some slack.
const POINTS : int = 38
const SEGMENT : float = 15.0
const GRAVITY : float = 700.0
## Air slows the free points, per second.
const DRAG : float = 2.0
const ITERATIONS : int = 8
## The hose lies on the floor rather than falling through it.
const FLOOR_Y : float = 352.0

var points : PackedVector2Array = PackedVector2Array()
var anchor : Vector2

var _previous : PackedVector2Array = PackedVector2Array()


func _init(tap : Vector2, nozzle : Vector2) -> void:
	anchor = tap
	points.resize(POINTS)
	for i : int in POINTS:
		points[i] = tap.lerp(nozzle, float(i) / (POINTS - 1))
	_previous = points.duplicate()


static func length() -> float:
	return SEGMENT * (POINTS - 1)


func nozzle() -> Vector2:
	return points[POINTS - 1]


## Where the nozzle can be: `target`, or as close as the hose reaches toward it.
func reachable(target : Vector2) -> Vector2:
	return anchor + (target - anchor).limit_length(length())


func step(delta : float, nozzle_target : Vector2) -> void:
	var damping : float = exp(-DRAG * delta)
	var last : int = POINTS - 1
	for i : int in range(1, last):
		var current : Vector2 = points[i]
		points[i] += (points[i] - _previous[i]) * damping + Vector2(0.0, GRAVITY) * delta * delta
		_previous[i] = current
	points[0] = anchor
	points[last] = reachable(nozzle_target)
	_previous[last] = points[last]
	for iteration : int in ITERATIONS:
		_keep_spacing()
		for i : int in range(1, last):
			points[i].y = minf(points[i].y, FLOOR_Y)
		points[0] = anchor
		points[last] = reachable(nozzle_target)


func _keep_spacing() -> void:
	for i : int in range(1, POINTS):
		var a : Vector2 = points[i - 1]
		var b : Vector2 = points[i]
		var offset : Vector2 = b - a
		var distance : float = offset.length()
		if distance <= SEGMENT or distance < 0.0001:
			continue
		var correction : Vector2 = offset * (distance - SEGMENT) / distance
		var a_fixed : bool = i == 1
		var b_fixed : bool = i == POINTS - 1
		if a_fixed and b_fixed:
			continue
		if a_fixed:
			points[i] = b - correction
		elif b_fixed:
			points[i - 1] = a + correction
		else:
			points[i - 1] = a + correction * 0.5
			points[i] = b - correction * 0.5
