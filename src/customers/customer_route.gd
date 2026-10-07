class_name CustomerRoute
extends RefCounted

## Walk maths for resuming a customer mid-route (CustomerSnapshot), so a loaded walk
## keeps the pace it had.


## Stair steps left from `position` to the stairs bottom, keeping the step length of the
## whole descent (`total_steps` from `start`). At least one while not there yet.
static func stair_steps_left(start : Vector2, stairs : Vector2, position : Vector2, total_steps : int) -> int:
	var total : float = start.distance_to(stairs)
	var left : float = position.distance_to(stairs)
	if total <= 0.0 or left <= 0.0:
		return 0
	return maxi(1, ceili(total_steps * left / total))


## Seconds to walk the rest of a straight leg at `speed` pixels per second.
static func seconds_left(position : Vector2, target : Vector2, speed : float) -> float:
	return position.distance_to(target) / maxf(speed, 0.001)
