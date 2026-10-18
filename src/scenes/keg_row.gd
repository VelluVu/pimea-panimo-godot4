class_name KegRow
extends Node2D

## The kegs behind the counter, one per batch on serve, front row first. Sorted in the world
## as one node, so every keg stays behind the bartender.


func show_kegs(count : int) -> void:
	var kegs : Array[Node] = get_children()
	kegs.sort_custom(func(a : Node2D, b : Node2D) -> bool:
		if not is_equal_approx(a.position.y, b.position.y):
			return a.position.y > b.position.y
		return a.position.x < b.position.x)
	for i : int in kegs.size():
		(kegs[i] as CanvasItem).visible = i < count
