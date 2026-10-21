class_name ShakeRules
extends RefCounted

## Screen shake from "trauma", 0 to 1: the offset grows with its square, so a shake fades
## out softly, and is whole game pixels, so the pixel art never sits between pixels.

const MAX_OFFSET_PX : float = 4.0
const DECAY_PER_SECOND : float = 1.6


## `random_x` and `random_y` are -1 to 1.
static func offset(trauma : float, random_x : float, random_y : float) -> Vector2i:
	var reach : float = clampf(trauma, 0.0, 1.0) ** 2 * MAX_OFFSET_PX
	return Vector2i(roundi(random_x * reach), roundi(random_y * reach))


static func decayed(trauma : float, seconds : float) -> float:
	return maxf(0.0, trauma - DECAY_PER_SECOND * seconds)


static func added(trauma : float, amount : float) -> float:
	return minf(1.0, trauma + amount)
