class_name MashClump
extends RefCounted

## A dough ball in the mash, broken by hard paddle swings (see MashSession). Positions
## and velocities are in liquid pixels, see MashSession.LIQUID_SIZE.

var position : Vector2 = Vector2.ZERO
var swipes_left : int = 2
var velocity : Vector2 = Vector2.ZERO
## Seconds before the paddle can hit it again.
var cooldown : float = 0.0


func _init(at : Vector2, swipes : int) -> void:
	position = at
	swipes_left = swipes


func is_broken() -> bool:
	return swipes_left <= 0
