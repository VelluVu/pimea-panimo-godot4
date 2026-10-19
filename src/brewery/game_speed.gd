class_name GameSpeed
extends RefCounted

## The player's fast-forward. Game time runs SPEEDS[index] times faster through
## Engine.time_scale, which every Timer, tween and animation follows; while the tree is
## paused it is back at 1x, so minigames under a pause keep their pace. Text the player
## reads waits in real seconds instead, see reading_timer().

const SPEEDS : Array[float] = [1.0, 2.0, 3.0]


static func next_index(index : int) -> int:
	return (index + 1) % SPEEDS.size()


static func time_scale(index : int, paused : bool) -> float:
	return 1.0 if paused else SPEEDS[index]


## A timer for a line on screen: as long in real time at any game speed.
static func reading_timer(tree : SceneTree, seconds : float) -> SceneTreeTimer:
	return tree.create_timer(seconds, true, false, true)
