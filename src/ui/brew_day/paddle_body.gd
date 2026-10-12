class_name PaddleBody
extends RefCounted

## The brew day paddle as a springy, slightly bendy stick: a chain of points held at
## a fixed spacing, with joints that pull back toward straight. The handle end chases
## the pointer on a loose spring and overshoots; the rest trails behind through the
## mash on its own momentum, so a wild sweep whips and bends the stick before it
## straightens out again. Both ends bounce off the kettle walls.

## The tip hit a wall; speed in pixels a second.
signal knocked(speed : float)

const POINTS : int = 7
const SEGMENT : float = 12.0
## The last segments are the blade; the rest is the shaft.
const BLADE_SEGMENTS : int = 2
const HANDLE_SPRING : float = 320.0
const HANDLE_DAMPING : float = 11.0
## A loose stick drifts back to rest much more gently.
const REST_SPRING : float = 40.0
## The mash slows the free points, per second.
const DRAG : float = 1.4
## How strongly each joint straightens per solver pass; low lets it bend.
const BEND_STIFFNESS : float = 0.4
## The handle is held, so the chain barely moves it.
const HANDLE_WEIGHT : float = 0.15
const ITERATIONS : int = 6
const SUBSTEPS : int = 3
const WALL_BOUNCE : float = 0.5
const KNOCK_SPEED : float = 140.0

var points : PackedVector2Array = PackedVector2Array()
var bounds : Rect2
var rest : Vector2
var rest_direction : Vector2

var _previous : PackedVector2Array = PackedVector2Array()
var _handle_velocity : Vector2 = Vector2.ZERO


func _init(area : Rect2, rest_handle : Vector2, direction : Vector2) -> void:
	bounds = area
	rest = rest_handle
	rest_direction = direction.normalized()
	reset()


func reset() -> void:
	points.resize(POINTS)
	for i : int in POINTS:
		points[i] = _inside(rest + rest_direction * SEGMENT * i)
	_previous = points.duplicate()
	_handle_velocity = Vector2.ZERO


func blade_from() -> int:
	return POINTS - 1 - BLADE_SEGMENTS


func length() -> float:
	var total : float = 0.0
	for i : int in range(1, POINTS):
		total += points[i - 1].distance_to(points[i])
	return total


## How far the stick is from straight: the tip's distance from where a straight stick
## along the first segment would end.
func bend() -> float:
	var direction : Vector2 = (points[1] - points[0]).normalized()
	return points[POINTS - 1].distance_to(points[0] + direction * SEGMENT * (POINTS - 1))


func step(delta : float, target : Vector2, held : bool) -> void:
	var dt : float = delta / SUBSTEPS
	var goal : Vector2 = _inside(target) if held else rest
	var spring : float = HANDLE_SPRING if held else REST_SPRING
	for substep : int in SUBSTEPS:
		var before : PackedVector2Array = points.duplicate()
		_handle_velocity += (spring * (goal - points[0]) - HANDLE_DAMPING * _handle_velocity) * dt
		points[0] += _handle_velocity * dt
		var damping : float = exp(-DRAG * dt)
		for i : int in range(1, POINTS):
			points[i] += (points[i] - _previous[i]) * damping
		_previous = before
		for iteration : int in ITERATIONS:
			_keep_spacing()
			_straighten()
			_keep_inside()
		_bounce_off_walls(dt)


func _keep_spacing() -> void:
	for i : int in range(1, POINTS):
		var a : Vector2 = points[i - 1]
		var b : Vector2 = points[i]
		var offset : Vector2 = b - a
		var distance : float = offset.length()
		if distance < 0.0001:
			continue
		var correction : Vector2 = offset * (distance - SEGMENT) / distance
		var weight_a : float = HANDLE_WEIGHT if i == 1 else 1.0
		var share_a : float = weight_a / (weight_a + 1.0)
		points[i - 1] = a + correction * share_a
		points[i] = b - correction * (1.0 - share_a)


## Each joint pulls the next point toward where a straight stick would put it.
func _straighten() -> void:
	for i : int in range(1, POINTS - 1):
		var direction : Vector2 = points[i] - points[i - 1]
		if direction.length() < 0.0001:
			continue
		var straight : Vector2 = points[i] + direction.normalized() * SEGMENT
		points[i + 1] = points[i + 1].lerp(straight, BEND_STIFFNESS)


func _keep_inside() -> void:
	for i : int in POINTS:
		points[i] = _inside(points[i])


## A point resting on a wall while still moving into it flies back off it.
func _bounce_off_walls(dt : float) -> void:
	for i : int in POINTS:
		for axis : int in 2:
			var low : float = bounds.position[axis]
			var high : float = bounds.end[axis]
			var motion : float = points[i][axis] - _previous[i][axis]
			var into_low : bool = points[i][axis] <= low + 0.01 and motion < 0.0
			var into_high : bool = points[i][axis] >= high - 0.01 and motion > 0.0
			if not into_low and not into_high:
				continue
			if i == 0:
				_handle_velocity[axis] *= -WALL_BOUNCE
				continue
			var previous : Vector2 = _previous[i]
			previous[axis] = points[i][axis] + motion * WALL_BOUNCE
			_previous[i] = previous
			if i == POINTS - 1 and absf(motion) / dt >= KNOCK_SPEED:
				knocked.emit(absf(motion) / dt)


func _inside(point : Vector2) -> Vector2:
	return point.clamp(bounds.position, bounds.end)
