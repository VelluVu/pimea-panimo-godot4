class_name KegRow
extends Node2D

## The kegs behind the counter: one shown per batch on serve, in child order, so the
## front row fills before the back one.


func show_kegs(count : int) -> void:
	var children : Array[Node] = get_children()
	for i : int in children.size():
		(children[i] as CanvasItem).visible = i < count
