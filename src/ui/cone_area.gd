class_name ConeArea
extends RefCounted

## A light cone as a trapezoid around x = 0, narrow at `top_y` and wide at `bottom_y`,
## for scattering things (dust specks) only where the light falls.


static func half_width_at(y : float, top_y : float, bottom_y : float, top_half : float, bottom_half : float) -> float:
	return lerpf(top_half, bottom_half, inverse_lerp(top_y, bottom_y, y))


## `count` whole-pixel points spread evenly over the cone's area.
static func random_points(count : int, top_y : float, bottom_y : float, top_half : float, bottom_half : float, rng : RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var widest : float = maxf(top_half, bottom_half)
	while points.size() < count:
		var at := Vector2(rng.randf_range(-widest, widest), rng.randf_range(top_y, bottom_y)).round()
		if absf(at.x) <= half_width_at(at.y, top_y, bottom_y, top_half, bottom_half):
			points.append(at)
	return points
