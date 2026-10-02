class_name CounterLayout
extends RefCounted

## Where customers stand at the counter. Up to the number of hand-placed markers the
## markers are used as they are; past that, the spots are spread evenly over the same
## span, so every extra spot tightens the spacing.


## `markers` are the hand-placed spots in slot order. Returns `count` spots in slot
## order: the first is the marker filled first today, then outward from it.
static func positions(markers : Array[Vector2], count : int) -> Array[Vector2]:
	if markers.is_empty() or count <= 0:
		return []
	if count <= markers.size():
		return markers.slice(0, count)

	var left : float = markers[0].x
	var right : float = markers[0].x
	var y_sum : float = 0.0
	for marker : Vector2 in markers:
		left = minf(left, marker.x)
		right = maxf(right, marker.x)
		y_sum += marker.y
	var y : float = y_sum / markers.size()

	var spots : Array[Vector2] = []
	for i : int in count:
		spots.append(Vector2(lerpf(left, right, float(i) / (count - 1)), y))
	var first_x : float = markers[0].x
	spots.sort_custom(func(a : Vector2, b : Vector2) -> bool:
		var da : float = absf(a.x - first_x)
		var db : float = absf(b.x - first_x)
		return da < db if not is_equal_approx(da, db) else a.x < b.x)
	return spots
