class_name KegRow
extends Node2D

## The kegs behind the counter: one shown per batch on serve, the front row filling
## before the back one, left to right. The row is sorted in the world as one node by its
## own position, so every keg stays behind the bartender; inside it the back kegs come
## first in the tree so the front ones are drawn over them.


func show_kegs(count : int) -> void:
	var kegs : Array[Node] = get_children()
	kegs.sort_custom(func(a : Node2D, b : Node2D) -> bool:
		if not is_equal_approx(a.position.y, b.position.y):
			return a.position.y > b.position.y
		return a.position.x < b.position.x)
	for i : int in kegs.size():
		(kegs[i] as CanvasItem).visible = i < count
