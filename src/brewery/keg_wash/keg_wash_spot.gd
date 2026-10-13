class_name KegWashSpot
extends RefCounted

## One thing inside a dirty keg: dirt to scrub loose and rinse away, a thing that pops out
## when hit, or critters that flee from the brush. See KegWashRules for each kind.

enum Kind { YEAST, GUM, SALMIAKKI, HAT, COCONUT, FLIES, BEES }
enum State { STUCK, LOOSE, FLEEING, GONE }

var kind : Kind
var position : Vector2
var state : State = State.STUCK
## Scrubbing done on a stuck spot, in pixels of brush stroke.
var work : float = 0.0
## Seconds of water on a loose spot.
var rinsed : float = 0.0
## Seconds left before fleeing critters are gone.
var flee_left : float = 0.0


func _init(spot_kind : Kind, at : Vector2) -> void:
	kind = spot_kind
	position = at


func is_gone() -> bool:
	return state == State.GONE
