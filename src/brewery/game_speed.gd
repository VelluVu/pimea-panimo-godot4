class_name GameSpeed
extends RefCounted

## The player's fast-forward. Game time runs SPEEDS[index] times faster through
## Engine.time_scale, which every Timer, tween and animation follows; while the tree is
## paused it is back at 1x, so minigames under a pause keep their pace. UI text the player
## reads and answers waits in real seconds instead, see reading_timer() and real_delta();
## customer speech bubbles follow the game speed.

const SPEEDS : Array[float] = [1.0, 2.0, 3.0]

## The speed the button applies right now (1.0 while paused). Only the player's speed is
## undone for reading: the playtest bots set Engine.time_scale themselves and leave this
## at 1, so their customers talk as fast as the rest of their game runs.
static var player_speed : float = 1.0


static func next_index(index : int) -> int:
	return (index + 1) % SPEEDS.size()


static func time_scale(index : int, paused : bool) -> float:
	return 1.0 if paused else SPEEDS[index]


## A timer for a line on screen: as long in real time at any player speed. It counts real
## seconds, so a speed change or a pause after it starts cannot stretch it past its bubble.
static func reading_timer(tree : SceneTree, seconds : float) -> SceneTreeTimer:
	return tree.create_timer(reading_seconds(seconds, Engine.time_scale), true, false, true)


## Real seconds for a `seconds` long line under `engine_time_scale`: only a bot's speed
## shortens it.
static func reading_seconds(seconds : float, engine_time_scale : float) -> float:
	return seconds * player_speed / maxf(engine_time_scale, 0.01)


## `delta` with the player's speed taken out, for countdowns the player answers.
static func real_delta(delta : float) -> float:
	return delta / player_speed
