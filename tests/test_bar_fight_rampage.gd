@tool
extends McpTestSuite


func suite_name() -> String:
	return "bar_fight_rampage"


func test_arc_starts_and_ends_on_its_points() -> void:
	var from := Vector2(0, -60)
	var to := Vector2(100, 10)
	assert_eq(BarFightRampage.arc_point(from, to, 70.0, 0.0), from)
	assert_eq(BarFightRampage.arc_point(from, to, 70.0, 1.0), to)


func test_arc_peaks_at_its_height_halfway() -> void:
	var point := BarFightRampage.arc_point(Vector2.ZERO, Vector2(100, 0), 70.0, 0.5)
	assert_true(point.is_equal_approx(Vector2(50, -70)))


func test_every_glass_is_thrown() -> void:
	for glasses in [0, 1, 3, 6, 9]:
		var thrown := 0
		for stomp in 6:
			thrown += BarFightRampage.share_of(stomp, glasses, 6)
		assert_eq(thrown, glasses, "%d glasses" % glasses)


func test_glasses_go_on_the_earliest_stomps() -> void:
	assert_eq(BarFightRampage.share_of(0, 2, 6), 1)
	assert_eq(BarFightRampage.share_of(1, 2, 6), 1)
	assert_eq(BarFightRampage.share_of(2, 2, 6), 0)
