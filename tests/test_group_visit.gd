@tool
extends McpTestSuite

## Unit tests for the group-visit crowd math added this session:
## CustomerSpawner's formation offset (keeps a crowd of customers from
## stacking on a single point) and GroupVisitEventData's plain resource
## defaults. The shared-order/chant flow itself needs a running game
## (CustomerManager, BrewEngine.current_brewery, real Customer nodes) and
## isn't covered here — see the class-level note in test_brew_resolver.gd
## for why that reach-into-autoload-state category isn't testable this way.


func suite_name() -> String:
	return "group_visit"


func _make_spawner() -> CustomerSpawner:
	return track(CustomerSpawner.new())


func test_formation_offset_centers_on_zero_for_odd_group() -> void:
	var spawner := _make_spawner()
	var total := 0.0
	for i in range(5):
		total += spawner._get_group_formation_offset(i, 5, 10.0).x
	assert_true(is_equal_approx(total, 0.0), "offsets should be symmetric around 0, sum=%s" % total)


func test_formation_offset_scales_with_spacing() -> void:
	var spawner := _make_spawner()
	var narrow := spawner._get_group_formation_offset(4, 5, 10.0).x
	var wide := spawner._get_group_formation_offset(4, 5, 20.0).x
	assert_true(is_equal_approx(wide, narrow * 2.0), "doubling spacing should double the offset, got %s vs %s" % [wide, narrow])


func test_formation_offset_alternates_rows() -> void:
	var spawner := _make_spawner()
	var even_row := spawner._get_group_formation_offset(0, 4, 10.0).y
	var odd_row := spawner._get_group_formation_offset(1, 4, 10.0).y
	assert_eq(even_row, 0.0, "even indices should sit on the front row")
	assert_ne(odd_row, 0.0, "odd indices should sit on a different row")


func test_group_visit_event_data_defaults() -> void:
	var event := GroupVisitEventData.new()
	assert_eq(event.banner_text, "")
	assert_eq(event.chant_text, "")
	assert_true(event.min_group_size <= event.max_group_size, "min_group_size should not exceed max_group_size")
