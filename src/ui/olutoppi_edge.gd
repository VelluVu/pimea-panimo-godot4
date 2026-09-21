class_name OlutoppiEdge
extends RefCounted

## Static geometry of one connector line and the node that gates it. Whether it is
## unlocked is recomputed on every refresh.

var from : Vector2
var to : Vector2
var prerequisite_id : String


func _init(from_center : Vector2, to_center : Vector2, prerequisite : String) -> void:
	from = from_center
	to = to_center
	prerequisite_id = prerequisite
