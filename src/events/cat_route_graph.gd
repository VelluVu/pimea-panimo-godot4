class_name CatRouteGraph
extends RefCounted

## The cellar cat's walkways: polylines whose points within MERGE_DISTANCE of each other join
## into one junction, searched with A*. A walk from anywhere steps onto the nearest point,
## follows the routes and steps off at the destination.

const MERGE_DISTANCE : float = 3.0

var _astar : AStar2D = AStar2D.new()


func _init(routes : Array[PackedVector2Array]) -> void:
	for route : PackedVector2Array in routes:
		var previous : int = -1
		for point : Vector2 in route:
			var id : int = _id_for(point)
			if previous >= 0 and previous != id:
				_astar.connect_points(previous, id)
			previous = id


func point_count() -> int:
	return _astar.get_point_count()


func point(index : int) -> Vector2:
	return _astar.get_point_position(_astar.get_point_ids()[index])


## The route points from `from` to `to`, both ends included; a straight line when there are
## no routes or the two share a nearest point.
func path(from : Vector2, to : Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	if point_count() > 0:
		var via : PackedVector2Array = _astar.get_point_path(_astar.get_closest_point(from), _astar.get_closest_point(to))
		for step : Vector2 in via:
			if not step.is_equal_approx(points[-1]):
				points.append(step)
	if not to.is_equal_approx(points[-1]):
		points.append(to)
	return points


func _id_for(at : Vector2) -> int:
	if point_count() > 0:
		var closest : int = _astar.get_closest_point(at)
		if _astar.get_point_position(closest).distance_to(at) <= MERGE_DISTANCE:
			return closest
	var id : int = _astar.get_available_point_id()
	_astar.add_point(id, at)
	return id
