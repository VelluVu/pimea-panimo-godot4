@tool
extends McpTestSuite

## Unit tests for CounterLayout's counter spots.

const LayoutScript := preload("res://src/customers/counter_layout.gd")


func suite_name() -> String:
	return "counter_layout"


func _markers() -> Array[Vector2]:
	return [Vector2(-50, 35), Vector2(-100, 35), Vector2(0, 36), Vector2(50, 35), Vector2(100, 36)]


func test_up_to_the_markers_they_are_used_as_they_are() -> void:
	assert_eq(LayoutScript.positions(_markers(), 5), _markers())
	assert_eq(LayoutScript.positions(_markers(), 3), _markers().slice(0, 3))


func test_extra_spots_spread_over_the_same_span() -> void:
	var spots : Array[Vector2] = LayoutScript.positions(_markers(), 9)
	assert_eq(spots.size(), 9)
	var xs : Array[float] = []
	for spot : Vector2 in spots:
		xs.append(spot.x)
	xs.sort()
	assert_eq(xs[0], -100.0)
	assert_eq(xs[-1], 100.0)
	assert_true(is_equal_approx(xs[1] - xs[0], 25.0), "even spacing")


func test_extra_spots_fill_from_the_first_marker_outward() -> void:
	var spots : Array[Vector2] = LayoutScript.positions(_markers(), 9)
	assert_eq(spots[0].x, -50.0)
	for i : int in range(1, spots.size()):
		assert_true(absf(spots[i].x + 50.0) >= absf(spots[i - 1].x + 50.0), "outward order")


func test_no_markers_means_no_spots() -> void:
	assert_eq(LayoutScript.positions([], 5).size(), 0)
