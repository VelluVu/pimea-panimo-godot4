@tool
extends McpTestSuite

## Unit tests for CatRouteGraph: junctions, paths and stepping on and off the routes.


func suite_name() -> String:
	return "cat_route_graph"


func _graph() -> CatRouteGraph:
	var routes : Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(200, 0)]),
		# Starts 2 px off the floor route's middle point: one junction, not two points.
		PackedVector2Array([Vector2(101, 2), Vector2(100, -100)]),
	]
	return CatRouteGraph.new(routes)


func test_close_points_join_into_one_junction() -> void:
	assert_eq(_graph().point_count(), 4)


func test_the_path_turns_at_the_junction() -> void:
	var path : PackedVector2Array = _graph().path(Vector2(0, 0), Vector2(100, -100))
	assert_eq(path, PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, -100)]))


func test_from_off_the_routes_he_steps_on_and_off() -> void:
	var path : PackedVector2Array = _graph().path(Vector2(5, 20), Vector2(195, 10))
	assert_eq(path[0], Vector2(5, 20))
	assert_eq(path[1], Vector2(0, 0))
	assert_eq(path[-2], Vector2(200, 0))
	assert_eq(path[-1], Vector2(195, 10))


func test_without_routes_the_path_is_a_straight_line() -> void:
	var empty : Array[PackedVector2Array] = []
	var path : PackedVector2Array = CatRouteGraph.new(empty).path(Vector2(1, 1), Vector2(9, 9))
	assert_eq(path, PackedVector2Array([Vector2(1, 1), Vector2(9, 9)]))
