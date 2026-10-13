class_name KegWashStain
extends RefCounted

## A coloured patch inside a dirty keg (old beer, hop slime, yeast). Only the hose takes
## it off; KegWashSession keeps how much of it is left per cell.

var center : Vector2
var radii : Vector2
var color : Color
var is_cleared : bool = false


func _init(at : Vector2, size : Vector2, stain_color : Color) -> void:
	center = at
	radii = size
	color = stain_color


## 0 at the centre, 1 on the edge; the edge wobbles a little so the patch is not a clean oval.
func reach(point : Vector2) -> float:
	var wobble : float = 0.12 * sin((point - center).angle() * 5.0 + center.x)
	return ((point - center) / radii).length() - wobble
