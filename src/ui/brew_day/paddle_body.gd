class_name PaddleBody
extends RefCounted

## The brew day paddle as a springy, slightly bendy stick: a chain of points held at
## a fixed spacing, with joints that pull back toward straight. points[0] is the blade
## tip, which follows the pointer on a loose spring inside the kettle mouth. The handle
## end leans up and out over the rim on the side away from the blade, and chases that
## spot with a lag: moving the blade across the mouth swings the shaft over the top to
## the other side. A wild sweep bends the stick before it straightens out again.

## The blade tip hit the kettle wall; speed in pixels a second.
signal knocked(speed : float)

const POINTS : int = 19
const SEGMENT : float = 12.0
## The first segments from the tip are the blade; the rest is the shaft.
const BLADE_SEGMENTS : int = 2
const TIP_SPRING : float = 320.0
const TIP_DAMPING : float = 15.0
## A loose paddle drifts back to rest much more gently.
const REST_SPRING : float = 40.0
## The handle follows its spot behind the blade loosely, so the shaft swings.
const HANDLE_SPRING : float = 90.0
const HANDLE_DAMPING : float = 11.0
## The shaft's lean: steep with the blade in the middle, nearly flat over the far rim
## with the blade at a wall (x is sideways, y upward, before normalizing).
const LEAN_MIDDLE : Vector2 = Vector2(0.6, 0.75)
const LEAN_WALL : Vector2 = Vector2(1.0, 0.3)
## Toward the back of the mouth the shaft leans lower, keeping the handle on screen.
const BACK_LEAN_SCALE : float = 0.5
## Air and mash slow the free middle points, per second.
const DRAG : float = 1.4
## How strongly each joint straightens per solver pass; low lets it bend.
const BEND_STIFFNESS : float = 0.55
## The two driven ends barely give way to the chain.
const END_WEIGHT : float = 0.15
const ITERATIONS : int = 6
const SUBSTEPS : int = 3
const WALL_BOUNCE : float = 0.5
const KNOCK_SPEED : float = 140.0

var points : PackedVector2Array = PackedVector2Array()
## The kettle mouth: the ellipse inside this rect holds the blade tip.
var mouth : Rect2
var rest : Vector2

var _previous : PackedVector2Array = PackedVector2Array()
var _tip_velocity : Vector2 = Vector2.ZERO
var _handle_velocity : Vector2 = Vector2.ZERO


func _init(kettle_mouth : Rect2, rest_tip : Vector2) -> void:
	mouth = kettle_mouth
	rest = rest_tip
	reset()


func reset() -> void:
	points.resize(POINTS)
	var tip : Vector2 = inside_mouth(rest)
	var direction : Vector2 = (handle_goal(tip) - tip).normalized()
	for i : int in POINTS:
		points[i] = tip + direction * SEGMENT * i
	_previous = points.duplicate()
	_tip_velocity = Vector2.ZERO
	_handle_velocity = Vector2.ZERO


func handle() -> Vector2:
	return points[POINTS - 1]


static func stick_length() -> float:
	return SEGMENT * (POINTS - 1)


func length() -> float:
	var total : float = 0.0
	for i : int in range(1, POINTS):
		total += points[i - 1].distance_to(points[i])
	return total


## How far the stick bows: the largest distance of a joint from the straight line
## between the tip and the handle.
func bend() -> float:
	var most : float = 0.0
	for i : int in range(1, POINTS - 1):
		var closest : Vector2 = Geometry2D.get_closest_point_to_segment(points[i], points[0], handle())
		most = maxf(most, closest.distance_to(points[i]))
	return most


## Where the handle wants to be: a stick's length from the tip, up and out on the side
## away from the blade.
func handle_goal(tip : Vector2) -> Vector2:
	var across : float = clampf((mouth.get_center().x - tip.x) / (mouth.size.x / 2.0), -1.0, 1.0)
	var side : float = -1.0 if across < 0.0 else 1.0
	var lean : Vector2 = LEAN_MIDDLE.lerp(LEAN_WALL, absf(across))
	var depth : float = clampf((tip.y - mouth.position.y) / mouth.size.y, 0.0, 1.0)
	lean.y *= lerpf(BACK_LEAN_SCALE, 1.0, depth)
	return tip + Vector2(side * lean.x, -lean.y).normalized() * stick_length()


func step(delta : float, target : Vector2, held : bool) -> void:
	var dt : float = delta / SUBSTEPS
	var goal : Vector2 = inside_mouth(target) if held else rest
	var spring : float = TIP_SPRING if held else REST_SPRING
	for substep : int in SUBSTEPS:
		var before : PackedVector2Array = points.duplicate()
		_tip_velocity += (spring * (goal - points[0]) - TIP_DAMPING * _tip_velocity) * dt
		points[0] += _tip_velocity * dt
		var last : int = POINTS - 1
		_handle_velocity += (HANDLE_SPRING * (handle_goal(points[0]) - points[last]) - HANDLE_DAMPING * _handle_velocity) * dt
		points[last] += _handle_velocity * dt
		var damping : float = exp(-DRAG * dt)
		for i : int in range(1, last):
			points[i] += (points[i] - _previous[i]) * damping
		_previous = before
		for iteration : int in ITERATIONS:
			_keep_spacing()
			_straighten()
		_keep_tip_in_mouth(dt)


func _keep_spacing() -> void:
	for i : int in range(1, POINTS):
		var a : Vector2 = points[i - 1]
		var b : Vector2 = points[i]
		var offset : Vector2 = b - a
		var distance : float = offset.length()
		if distance < 0.0001:
			continue
		var correction : Vector2 = offset * (distance - SEGMENT) / distance
		var weight_a : float = END_WEIGHT if i == 1 else 1.0
		var weight_b : float = END_WEIGHT if i == POINTS - 1 else 1.0
		var share_a : float = weight_a / (weight_a + weight_b)
		points[i - 1] = a + correction * share_a
		points[i] = b - correction * (1.0 - share_a)


## Each middle joint moves toward the midpoint of its neighbours, which straightens the
## stick without dragging either driven end along.
func _straighten() -> void:
	for i : int in range(1, POINTS - 1):
		points[i] = points[i].lerp((points[i - 1] + points[i + 1]) / 2.0, BEND_STIFFNESS)


## The blade stays in the mash; hitting the wall bounces it back and knocks.
func _keep_tip_in_mouth(dt : float) -> void:
	var inside : Vector2 = inside_mouth(points[0])
	if inside.is_equal_approx(points[0]):
		return
	var normal : Vector2 = (points[0] - inside).normalized()
	var into_wall : float = _tip_velocity.dot(normal)
	points[0] = inside
	if into_wall > 0.0:
		_tip_velocity -= normal * into_wall * (1.0 + WALL_BOUNCE)
		if into_wall >= KNOCK_SPEED:
			knocked.emit(into_wall)
	_previous[0] = points[0] - _tip_velocity * dt


## The nearest point inside the mouth's ellipse.
func inside_mouth(point : Vector2) -> Vector2:
	var half : Vector2 = mouth.size / 2.0
	var offset : Vector2 = (point - mouth.get_center()) / half
	if offset.length() <= 1.0:
		return point
	return mouth.get_center() + offset.normalized() * half
