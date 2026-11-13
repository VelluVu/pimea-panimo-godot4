class_name CellarCatRules
extends RefCounted

## What the adopted cellar cat does next and for how long. A cat's day: sit and look about,
## doze off, wake with a stretch, groom, wander the cellar, peek into the brewery or the
## warehouse, and chase the pests.

enum Act { SIT, SLEEP, GROOM, STRETCH, WALK, PEEK }
## Where a walk goes: a resting spot, a look inside a side room, or anywhere on the routes.
enum Destination { REST, PEEK, ROAM }

## Act -> [next act, chance] pairs; the chances of one act add up to 1.
const NEXT : Dictionary = {
	Act.SIT: [[Act.SLEEP, 0.35], [Act.GROOM, 0.3], [Act.WALK, 0.25], [Act.STRETCH, 0.1]],
	Act.SLEEP: [[Act.STRETCH, 1.0]],
	Act.GROOM: [[Act.SIT, 1.0]],
	Act.STRETCH: [[Act.WALK, 0.6], [Act.SIT, 0.4]],
	Act.WALK: [[Act.SIT, 0.75], [Act.GROOM, 0.25]],
	Act.PEEK: [[Act.WALK, 1.0]],
}
const DESTINATIONS : Array = [[Destination.REST, 0.55], [Destination.PEEK, 0.25], [Destination.ROAM, 0.2]]

## Seconds the looping acts last, as [shortest, longest]; groom and stretch play once.
const SECONDS : Dictionary = {
	Act.SIT: Vector2(8.0, 20.0),
	Act.SLEEP: Vector2(30.0, 90.0),
	Act.PEEK: Vector2(3.0, 8.0),
}

## Art pixels a second, so a far (smaller) cat also covers less screen.
const WALK_ART_PIXELS_PER_SECOND : float = 12.0
## A chase runs this much faster, and so does the walk cycle.
const CHASE_SPEED_FACTOR : float = 2.5
## A leg steeper than this, upwards, shows his back: he walks away towards the back wall.
const AWAY_STEEPNESS : float = 0.5
## In front of this line he shares the customers' layer (z 1) and sorts with them; behind it
## the counter, kegs and tree (z 0).
const FRONT_FLOOR_Y : float = 286.0
## Where he can chase a pest: the open floor, not up the stairs or walls.
const CHASE_FLOOR : Rect2 = Rect2(-10.0, 262.0, 610.0, 98.0)
const CHASE_MAX_SECONDS : float = 4.0
const CHASE_REACT_SECONDS : float = 0.4
## Seconds he sits and watches a flying pest.
const WATCH_SECONDS : Vector2 = Vector2(3.0, 5.0)


## `roll` in [0, 1): the same roll always gives the same act.
static func next_act(current : Act, roll : float) -> Act:
	return _pick(NEXT[current], roll) as Act


static func destination(roll : float) -> Destination:
	return _pick(DESTINATIONS, roll) as Destination


## Zero for the acts that end with their animation.
static func act_seconds(act : Act, roll : float) -> float:
	if not SECONDS.has(act):
		return 0.0
	var span : Vector2 = SECONDS[act]
	return lerpf(span.x, span.y, roll)


static func loops(act : Act) -> bool:
	return SECONDS.has(act)


## Another spot than `current` (any when there is one or `current` is -1).
static func next_spot(count : int, current : int, roll : float) -> int:
	if count <= 1 or current < 0:
		return clampi(int(roll * count), 0, maxi(count - 1, 0))
	var pick : int = clampi(int(roll * (count - 1)), 0, count - 2)
	return pick + 1 if pick >= current else pick


## Screen pixels a second at sprite scale `scale`.
static func walk_speed(scale : float) -> float:
	return WALK_ART_PIXELS_PER_SECOND * scale


static func walk_animation(direction : Vector2) -> StringName:
	if direction.y < 0.0 and -direction.y > absf(direction.x) * AWAY_STEEPNESS:
		return &"walk_back"
	return &"walk_left"


static func z_index_at(y : float) -> int:
	return 1 if y >= FRONT_FLOOR_Y else 0


static func chase_target(pest_position : Vector2) -> Vector2:
	return pest_position.clamp(CHASE_FLOOR.position, CHASE_FLOOR.end)


static func animation(act : Act) -> StringName:
	match act:
		Act.SIT, Act.PEEK: return &"sit"
		Act.SLEEP: return &"sleep"
		Act.GROOM: return &"groom"
		Act.STRETCH: return &"stretch"
	return &"walk_left"


static func _pick(options : Array, roll : float) -> int:
	var total : float = 0.0
	for option : Array in options:
		total += option[1]
		if roll < total:
			return option[0]
	return options[-1][0]
