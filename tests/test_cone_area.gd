@tool
extends McpTestSuite

## Unit tests for ConeArea: points scattered inside a light cone.

const ConeAreaScript := preload("res://src/ui/cone_area.gd")


func suite_name() -> String:
	return "cone_area"


func test_half_width_grows_from_top_to_bottom() -> void:
	assert_eq(ConeAreaScript.half_width_at(-80.0, -80.0, 70.0, 20.0, 100.0), 20.0)
	assert_eq(ConeAreaScript.half_width_at(70.0, -80.0, 70.0, 20.0, 100.0), 100.0)
	assert_eq(ConeAreaScript.half_width_at(-5.0, -80.0, 70.0, 20.0, 100.0), 60.0)


func test_every_point_is_inside_the_cone_and_whole() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var points : PackedVector2Array = ConeAreaScript.random_points(300, -80.0, 70.0, 20.0, 100.0, rng)
	assert_eq(points.size(), 300)
	for at : Vector2 in points:
		assert_true(at.y >= -80.0 and at.y <= 70.0, str(at))
		assert_true(absf(at.x) <= ConeAreaScript.half_width_at(at.y, -80.0, 70.0, 20.0, 100.0), str(at))
		assert_eq(at, at.round())


func test_the_narrow_top_gets_fewer_points_than_the_wide_bottom() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var top : int = 0
	for at : Vector2 in ConeAreaScript.random_points(400, -80.0, 70.0, 20.0, 100.0, rng):
		if at.y < -5.0:
			top += 1
	assert_true(top < 200, str(top))
