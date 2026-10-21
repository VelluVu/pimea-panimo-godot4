class_name PixelLine
extends RefCounted

## Whole-pixel lines (Bresenham), for drawing pixel art that turns, like a clock hand,
## without the bent pixels a rotated texture gets.


## Every pixel from `from` to `to`, both ends included, one per step along the longer axis.
static func points(from : Vector2i, to : Vector2i) -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	var delta : Vector2i = (to - from).abs()
	var step : Vector2i = Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var error : int = delta.x - delta.y
	var at : Vector2i = from
	while true:
		result.append(at)
		if at == to:
			break
		var doubled : int = error * 2
		if doubled > -delta.y:
			error -= delta.y
			at.x += step.x
		if doubled < delta.x:
			error += delta.x
			at.y += step.y
	return result


## The pixel `length` away from `hub` at `angle`, clockwise from straight up.
static func tip(hub : Vector2i, angle : float, length : float) -> Vector2i:
	return hub + Vector2i(roundi(sin(angle) * length), roundi(-cos(angle) * length))
