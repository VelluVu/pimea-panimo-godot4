@tool
extends McpTestSuite

## Unit tests for the pure part of customer spawning: the interval bounds in
## CustomerSpawner. Loaded by path so the suite always runs the script as it is
## on disk. Crowd formation is covered in test_group_visit.gd.

const CustomerSpawnerScript := preload("res://src/classes/customer_spawner.gd")


func suite_name() -> String:
	return "customer_spawning"


func test_interval_bounds_scale_the_base_range_by_the_factor() -> void:
	var bounds : Vector2 = CustomerSpawnerScript.interval_bounds(30.0, 90.0, 10.0, 1.0)
	assert_eq(bounds, Vector2(30.0, 90.0))
	bounds = CustomerSpawnerScript.interval_bounds(30.0, 90.0, 10.0, 0.5)
	assert_eq(bounds, Vector2(15.0, 45.0))


func test_interval_bounds_never_drop_below_the_floor() -> void:
	var bounds : Vector2 = CustomerSpawnerScript.interval_bounds(30.0, 90.0, 10.0, 0.01)
	assert_eq(bounds, Vector2(10.0, 10.0))


func test_interval_max_is_never_below_min() -> void:
	var bounds : Vector2 = CustomerSpawnerScript.interval_bounds(30.0, 90.0, 60.0, 0.5)
	assert_eq(bounds.x, 60.0)
	assert_true(bounds.y >= bounds.x)
