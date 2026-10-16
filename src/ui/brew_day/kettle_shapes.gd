class_name KettleShapes
extends RefCounted

## Pixel-snapped ellipses for the kettle's drawing, and the mouth's unit space: the
## liquid's middle at the origin and its edge on the unit circle, so a swirl just
## rotates a place.

const ELLIPSE_POINTS : int = 48


## Snapped to whole pixels without repeating a point, which would break the fill.
static func ellipse(rect : Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i : int in ELLIPSE_POINTS:
		var angle : float = TAU * i / ELLIPSE_POINTS
		var point : Vector2 = (rect.get_center() + Vector2(cos(angle), sin(angle)) * rect.size / 2.0).round()
		if points.is_empty() or not point.is_equal_approx(points[points.size() - 1]):
			points.append(point)
	if points.size() > 1 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	return points


## Fills an ellipse, skipping one too small or thin to have an inside.
static func fill_ellipse(canvas : CanvasItem, rect : Rect2, color : Color) -> void:
	var points : PackedVector2Array = ellipse(rect)
	if points.size() >= 3 and not Geometry2D.triangulate_polygon(points).is_empty():
		canvas.draw_colored_polygon(points, color)


static func outline_ellipse(canvas : CanvasItem, rect : Rect2, color : Color, width : float) -> void:
	var points : PackedVector2Array = ellipse(rect)
	points.append(points[0])
	canvas.draw_polyline(points, color, width)


static func in_ellipse(rect : Rect2, point : Vector2) -> bool:
	return ((point - rect.get_center()) / (rect.size / 2.0)).length() <= 1.0


static func to_unit(point : Vector2) -> Vector2:
	return (point - KettleView.LIQUID_RECT.get_center()) / (KettleView.LIQUID_RECT.size / 2.0)


static func from_unit(place : Vector2) -> Vector2:
	return KettleView.LIQUID_RECT.get_center() + place * KettleView.LIQUID_RECT.size / 2.0


## `progress` 0..1 held at `steps` solid steps, so an effect changes like pixel art.
static func stepped(progress : float, steps : float) -> float:
	return floorf(progress * steps) / steps
