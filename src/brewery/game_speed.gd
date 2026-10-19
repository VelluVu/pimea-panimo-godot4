class_name GameSpeed
extends RefCounted

## The player's fast-forward. Game time runs SPEEDS[index] times faster through
## Engine.time_scale, which every Timer, tween and animation follows; while the tree is
## paused it is back at 1x, so minigames under a pause keep their pace. Text the player
## reads and answers waits in real seconds instead, see reading_timer() and real_delta().

const SPEEDS : Array[float] = [1.0, 2.0, 3.0]

## The speed the button applies right now (1.0 while paused). Only the player's speed is
## undone for reading: the playtest bots set Engine.time_scale themselves and leave this
## at 1, so their customers talk as fast as the rest of their game runs.
static var player_speed : float = 1.0


static func next_index(index : int) -> int:
	return (index + 1) % SPEEDS.size()


static func time_scale(index : int, paused : bool) -> float:
	return 1.0 if paused else SPEEDS[index]


## A timer for a line on screen: as long in real time at any player speed.
static func reading_timer(tree : SceneTree, seconds : float) -> SceneTreeTimer:
	return tree.create_timer(seconds * player_speed)


## `delta` with the player's speed taken out, for countdowns the player answers.
static func real_delta(delta : float) -> float:
	return delta / player_speed
