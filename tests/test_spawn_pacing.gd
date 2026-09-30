@tool
extends McpTestSuite

## Crowd formation is covered in test_group_visit.gd.


func suite_name() -> String:
	return "spawn_pacing"


func test_interval_bounds_scale_the_base_range_by_the_factor() -> void:
	assert_eq(SpawnPacing.interval_bounds(30.0, 90.0, 10.0, 1.0), Vector2(30.0, 90.0))
	assert_eq(SpawnPacing.interval_bounds(30.0, 90.0, 10.0, 0.5), Vector2(15.0, 45.0))


func test_interval_bounds_never_drop_below_the_floor() -> void:
	assert_eq(SpawnPacing.interval_bounds(30.0, 90.0, 10.0, 0.01), Vector2(10.0, 10.0))


func test_interval_max_is_never_below_min() -> void:
	var bounds := SpawnPacing.interval_bounds(30.0, 90.0, 60.0, 0.5)
	assert_eq(bounds.x, 60.0)
	assert_true(bounds.y >= bounds.x)


func test_reputation_factor_halves_at_the_soft_cap() -> void:
	assert_eq(SpawnPacing.reputation_factor(0.0), 1.0)
	assert_eq(SpawnPacing.reputation_factor(SpawnPacing.REPUTATION_SPAWN_SOFT_CAP), 0.5)


func test_walk_in_bounds_at_zero_reputation_are_the_base_range() -> void:
	var bounds := SpawnPacing.walk_in_bounds(0.0, 1.0)
	assert_eq(bounds, Vector2(SpawnPacing.WALK_IN_INTERVAL_MIN_SECONDS, SpawnPacing.WALK_IN_INTERVAL_MAX_SECONDS))


func test_walk_in_bounds_shrink_with_reputation_and_perks() -> void:
	var base := SpawnPacing.walk_in_bounds(0.0, 1.0)
	assert_true(SpawnPacing.walk_in_bounds(100.0, 1.0).y < base.y)
	assert_true(SpawnPacing.walk_in_bounds(0.0, 0.75).y < base.y)


func test_group_multiplier_only_affects_group_bounds() -> void:
	var base := SpawnPacing.group_bounds(0.0, 1.0, 1.0)
	var boosted := SpawnPacing.group_bounds(0.0, 1.0, 0.8)
	assert_eq(boosted.y, base.y * 0.8)


func test_group_bounds_respect_their_floor() -> void:
	var bounds := SpawnPacing.group_bounds(10000.0, 0.1, 0.1)
	assert_eq(bounds, Vector2(SpawnPacing.GROUP_EVENT_FLOOR_SECONDS, SpawnPacing.GROUP_EVENT_FLOOR_SECONDS))
