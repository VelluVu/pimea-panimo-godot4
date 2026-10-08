class_name TouchHold
extends RefCounted

## Tells a press-and-hold from a tap or a drag: fires once when a finger has stayed down
## within SLOP pixels for HOLD_SECONDS.

## A deliberate tap can last half a second, so a hold needs a little longer.
const HOLD_SECONDS: float = 0.6
## A finger wobbles; moving further than this is a drag (scrolling), not a hold.
const SLOP: float = 10.0

var _start: Vector2
var _held_for: float = 0.0
var _is_down: bool = false
var _has_fired: bool = false


func press(position: Vector2) -> void:
	_start = position
	_held_for = 0.0
	_is_down = true
	_has_fired = false


func move(position: Vector2) -> void:
	if _is_down and position.distance_to(_start) > SLOP:
		_is_down = false


func release() -> void:
	_is_down = false


## True on the one tick the hold completes.
func tick(delta: float) -> bool:
	if not _is_down or _has_fired:
		return false
	_held_for += delta
	if _held_for < HOLD_SECONDS:
		return false
	_has_fired = true
	return true


## Whether the current (or just released) press turned into a hold.
func has_fired() -> bool:
	return _has_fired
