@tool
extends McpTestSuite

## Unit tests for PixelLine: whole-pixel lines and hand tips.

const PixelLineScript := preload("res://src/ui/pixel_line.gd")


func suite_name() -> String:
	return "pixel_line"


func test_a_vertical_line_has_every_pixel() -> void:
	var line : Array[Vector2i] = PixelLineScript.points(Vector2i(16, 16), Vector2i(16, 3))
	assert_eq(line.size(), 14)
	assert_eq(line[0], Vector2i(16, 16))
	assert_eq(line[-1], Vector2i(16, 3))


func test_a_diagonal_steps_one_pixel_each_way() -> void:
	var line : Array[Vector2i] = PixelLineScript.points(Vector2i(0, 0), Vector2i(3, 3))
	assert_eq(line, [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)] as Array[Vector2i])


func test_a_shallow_line_has_one_pixel_per_column() -> void:
	var line : Array[Vector2i] = PixelLineScript.points(Vector2i(0, 0), Vector2i(6, -2))
	assert_eq(line.size(), 7)
	for i : int in line.size():
		assert_eq(line[i].x, i)


func test_neighbouring_pixels_always_touch() -> void:
	var line : Array[Vector2i] = PixelLineScript.points(Vector2i(16, 16), Vector2i(5, 24))
	for i : int in range(1, line.size()):
		var gap : Vector2i = (line[i] - line[i - 1]).abs()
		assert_true(gap.x <= 1 and gap.y <= 1, str(line[i]))


func test_a_single_point_line() -> void:
	assert_eq(PixelLineScript.points(Vector2i(4, 4), Vector2i(4, 4)).size(), 1)


func test_tip_points_up_at_zero_and_right_at_a_quarter() -> void:
	assert_eq(PixelLineScript.tip(Vector2i(16, 16), 0.0, 13.0), Vector2i(16, 3))
	assert_eq(PixelLineScript.tip(Vector2i(16, 16), TAU * 0.25, 13.0), Vector2i(29, 16))
