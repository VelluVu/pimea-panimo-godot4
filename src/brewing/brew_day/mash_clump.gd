class_name MashClump
extends RefCounted

## A dough ball in the mash. The paddle breaks it by passing through it: entering and
## leaving again counts as one swipe. Positions are in the liquid's 0..1 space.

var position : Vector2 = Vector2.ZERO
var swipes_left : int = 2
var paddle_inside : bool = false


func _init(at : Vector2, swipes : int) -> void:
	position = at
	swipes_left = swipes


func is_broken() -> bool:
	return swipes_left <= 0
