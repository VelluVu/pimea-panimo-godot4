class_name KettleMouth
extends RefCounted

## The kettle sprite's mouth in its own art pixels: the hole, the rim around it, and the
## strip of inner wall above a lowered waterline. Drawn as whole art pixels, so what lies
## over the 4x kettle steps like its art instead of in finer screen pixels.


## Transparent pixels with the kettle on both sides in their row: the hole, not the air
## above or beside the kettle.
static func hole_cells(art : Image) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	for y : int in art.get_height():
		var first : int = -1
		var last : int = -1
		for x : int in art.get_width():
			if art.get_pixel(x, y).a > 0.0:
				if first == -1:
					first = x
				last = x
		for x : int in range(first + 1, last):
			if art.get_pixel(x, y).a == 0.0:
				cells.append(Vector2i(x, y))
	return cells


## Kettle pixels touching the hole side by side: the rim's inner edge.
static func rim_cells(art : Image, hole : Array[Vector2i]) -> Array[Vector2i]:
	var in_hole : Dictionary = {}
	for cell : Vector2i in hole:
		in_hole[cell] = true
	var rim : Dictionary = {}
	for cell : Vector2i in hole:
		for step : Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var near : Vector2i = cell + step
			if not in_hole.has(near) and near.x >= 0 and near.y >= 0 and near.x < art.get_width() and near.y < art.get_height():
				rim[near] = true
	var cells : Array[Vector2i] = []
	cells.assign(rim.keys())
	return cells


## Hole cells above the waterline: the liquid is the ellipse in `liquid` (art pixels), and a
## cell whose middle lies above its upper edge shows the inner wall.
static func wall_cells(hole : Array[Vector2i], liquid : Rect2) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var middle : Vector2 = liquid.get_center()
	var radius : Vector2 = liquid.size / 2.0
	for cell : Vector2i in hole:
		var at : Vector2 = Vector2(cell) + Vector2(0.5, 0.5)
		var across : float = (at.x - middle.x) / radius.x
		if absf(across) >= 1.0 or at.y < middle.y - radius.y * sqrt(1.0 - across * across):
			if at.y < middle.y:
				cells.append(cell)
	return cells
