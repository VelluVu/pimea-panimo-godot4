class_name BoilMark
extends RefCounted

## One addition on the boil's timeline: which sack, how much, when, and how it went.

enum Result { OPEN, FULL, HALF, MISS }

var kind : HopAddition.Kind = HopAddition.Kind.BITTERING
var ingredient_id : int = -1
var grams : int = 0
var time : float = 0.0
var result : Result = Result.OPEN
## A flavour or aroma mark given a hop with no aroma (a bittering hop like Magnum):
## even a perfect pour of it is only half a hit.
var bittering_only : bool = false


func _init(new_kind : HopAddition.Kind = HopAddition.Kind.BITTERING, id : int = -1, amount : int = 0) -> void:
	kind = new_kind
	ingredient_id = id
	grams = amount
	time = BoilSchedule.time_for(new_kind)


func is_open() -> bool:
	return result == Result.OPEN


func points() -> float:
	match result:
		Result.FULL: return 1.0
		Result.HALF: return 0.5
		_: return 0.0
