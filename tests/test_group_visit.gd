@tool
extends McpTestSuite

## Unit tests for the group-visit crowd math: GroupVisitDirector's formation
## offset (keeps a crowd from stacking on one point) and GroupVisitEventData's
## plain resource defaults. The shared order and chant flow needs a running game
## (real Customer nodes and autoloads), so it is checked there instead.


func suite_name() -> String:
	return "group_visit"


func test_formation_offset_centers_on_zero_for_odd_group() -> void:
	var total := 0.0
	for i in range(5):
		total += GroupVisitDirector.formation_offset(i, 5, 10.0).x
	assert_true(is_equal_approx(total, 0.0), "offsets should be symmetric around 0, sum=%s" % total)


func test_formation_offset_scales_with_spacing() -> void:
	var narrow := GroupVisitDirector.formation_offset(4, 5, 10.0).x
	var wide := GroupVisitDirector.formation_offset(4, 5, 20.0).x
	assert_true(is_equal_approx(wide, narrow * 2.0), "doubling spacing should double the offset, got %s vs %s" % [wide, narrow])


func test_formation_offset_alternates_rows() -> void:
	var even_row := GroupVisitDirector.formation_offset(0, 4, 10.0).y
	var odd_row := GroupVisitDirector.formation_offset(1, 4, 10.0).y
	assert_eq(even_row, 0.0, "even indices should sit on the front row")
	assert_ne(odd_row, 0.0, "odd indices should sit on a different row")


func test_formation_members_never_share_a_spot() -> void:
	var seen : Dictionary = {}
	for index : int in range(10):
		var offset : Vector2 = GroupVisitDirector.formation_offset(index, 10, 30.0)
		assert_false(seen.has(offset), "members share the spot %s" % offset)
		seen[offset] = true


func test_group_visit_event_data_defaults() -> void:
	var event := GroupVisitEventData.new()
	assert_eq(event.banner_text, "")
	assert_true(event.chant_texts.is_empty())
	assert_true(event.min_group_size <= event.max_group_size, "min_group_size should not exceed max_group_size")


func test_get_chant_text_empty_when_no_chants() -> void:
	var event := GroupVisitEventData.new()
	assert_eq(event.get_chant_text(0), "")


func test_get_chant_text_sequence_cycles_in_order() -> void:
	var event := GroupVisitEventData.new()
	event.chant_texts = ["one", "two", "three"]
	event.chant_mode = GroupVisitEventData.ChantMode.SEQUENCE

	assert_eq(event.get_chant_text(0), "one")
	assert_eq(event.get_chant_text(1), "two")
	assert_eq(event.get_chant_text(2), "three")
	assert_eq(event.get_chant_text(3), "one", "sequence should wrap back around via modulo")


func test_get_chant_text_random_only_returns_listed_lines() -> void:
	var event := GroupVisitEventData.new()
	event.chant_texts = ["one", "two", "three"]
	event.chant_mode = GroupVisitEventData.ChantMode.RANDOM

	for i in range(20):
		assert_true(event.chant_texts.has(event.get_chant_text(i)), "RANDOM should only ever return a line from chant_texts")


func test_roll_group_size_stays_within_the_range() -> void:
	for attempt : int in range(50):
		var size : int = GroupVisitDirector.roll_group_size(3, 8)
		assert_true(size >= 3 and size <= 8, "size %d is outside 3..8" % size)


func test_roll_group_size_with_a_single_size_range_returns_it() -> void:
	assert_eq(GroupVisitDirector.roll_group_size(4, 4), 4)


func _make_options(randomizes : bool = false) -> Array[CustomerData]:
	var data := CustomerData.new()
	data.min_bottles_per_visit = 1
	data.max_bottles_per_visit = 2
	data.randomizes_preference = randomizes
	var options : Array[CustomerData] = [data]
	return options


func test_build_order_data_scales_the_bottle_range_by_crowd_size() -> void:
	var order : CustomerData = GroupVisitDirector.build_order_data(_make_options(), 4, [])
	assert_eq(order.min_bottles_per_visit, 4)
	assert_eq(order.max_bottles_per_visit, 8)


func test_build_order_data_leaves_the_shared_resource_untouched() -> void:
	var options := _make_options()
	var order : CustomerData = GroupVisitDirector.build_order_data(options, 4, [])
	assert_ne(order, options[0], "the order is a copy")
	assert_eq(options[0].min_bottles_per_visit, 1)
	assert_eq(options[0].max_bottles_per_visit, 2)


func test_group_visit_knows_when_nobody_is_left() -> void:
	var visit := GroupVisit.new(GroupVisitEventData.new(), 0, 10, Vector2.ZERO)
	assert_false(visit.has_anyone_here(), "no members yet")

	var member := Node2D.new()
	visit.members.append(member)
	assert_true(visit.has_anyone_here())

	member.free()
	assert_false(visit.has_anyone_here(), "a freed member must not count or throw")
	assert_eq(visit.size(), 1, "the roster keeps its size, as the order scales by it")
