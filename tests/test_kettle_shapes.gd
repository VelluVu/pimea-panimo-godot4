@tool
extends McpTestSuite

## Unit tests for KettleShapes: pixel ellipses and the mouth's unit space.

const ShapesScript := preload("res://src/ui/brew_day/kettle_shapes.gd")


func suite_name() -> String:
	return "kettle_shapes"


func test_an_ellipse_never_repeats_a_point() -> void:
	for rect : Rect2 in [Rect2(0, 0, 232, 104), Rect2(10, 10, 6, 3), Rect2(0, 0, 2, 2)]:
		var points : PackedVector2Array = ShapesScript.ellipse(rect)
		for i : int in points.size():
			assert_false(points[i].is_equal_approx(points[(i + 1) % points.size()]), "%s point %d" % [rect, i])


func test_ellipse_points_are_whole_pixels_on_the_rect() -> void:
	var rect := Rect2(24, 44, 232, 104)
	for point : Vector2 in ShapesScript.ellipse(rect):
		assert_eq(point, point.round())
		assert_true(rect.grow(0.5).has_point(point))


func test_unit_space_round_trips_and_puts_the_edge_on_the_unit_circle() -> void:
	var liquid : Rect2 = KettleView.LIQUID_RECT
	assert_eq(ShapesScript.to_unit(liquid.get_center()), Vector2.ZERO)
	assert_eq(ShapesScript.to_unit(Vector2(liquid.end.x, liquid.get_center().y)), Vector2(1, 0))
	var point := Vector2(100, 70)
	assert_true(ShapesScript.from_unit(ShapesScript.to_unit(point)).is_equal_approx(point))


func test_in_ellipse_excludes_the_rects_corners() -> void:
	var rect := Rect2(0, 0, 100, 50)
	assert_true(ShapesScript.in_ellipse(rect, rect.get_center()))
	assert_true(ShapesScript.in_ellipse(rect, Vector2(100, 25)))
	assert_false(ShapesScript.in_ellipse(rect, Vector2(2, 2)))


func test_stepped_holds_each_step() -> void:
	assert_eq(ShapesScript.stepped(0.0, 4.0), 0.0)
	assert_eq(ShapesScript.stepped(0.24, 4.0), 0.0)
	assert_eq(ShapesScript.stepped(0.26, 4.0), 0.25)
	assert_eq(ShapesScript.stepped(1.0, 4.0), 1.0)
