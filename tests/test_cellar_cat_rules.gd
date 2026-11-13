@tool
extends McpTestSuite

## Unit tests for CellarCatRules: the cat's next act, how long it lasts and where it walks.

const Act := CellarCatRules.Act


func suite_name() -> String:
	return "cellar_cat_rules"


func test_every_act_has_chances_that_add_up_to_one() -> void:
	for act : int in CellarCatRules.NEXT:
		var total : float = 0.0
		for option : Array in CellarCatRules.NEXT[act]:
			total += option[1]
		assert_true(is_equal_approx(total, 1.0), "act %d adds up to %f" % [act, total])


func test_he_always_stretches_after_a_nap() -> void:
	for roll : float in [0.0, 0.5, 0.99]:
		assert_eq(CellarCatRules.next_act(Act.SLEEP, roll), Act.STRETCH)


func test_he_never_naps_right_after_a_walk() -> void:
	for roll : float in [0.0, 0.3, 0.6, 0.99]:
		assert_ne(CellarCatRules.next_act(Act.WALK, roll), Act.SLEEP)


func test_the_roll_walks_through_the_options_in_order() -> void:
	assert_eq(CellarCatRules.next_act(Act.SIT, 0.0), Act.SLEEP)
	assert_eq(CellarCatRules.next_act(Act.SIT, 0.5), Act.GROOM)
	assert_eq(CellarCatRules.next_act(Act.SIT, 0.99), Act.STRETCH)


func test_a_roll_of_one_still_gives_an_act() -> void:
	assert_eq(CellarCatRules.next_act(Act.SIT, 1.0), Act.STRETCH)


func test_sitting_and_sleeping_last_their_span_the_rest_end_with_the_animation() -> void:
	assert_eq(CellarCatRules.act_seconds(Act.SLEEP, 0.0), 30.0)
	assert_eq(CellarCatRules.act_seconds(Act.SLEEP, 1.0), 90.0)
	assert_eq(CellarCatRules.act_seconds(Act.GROOM, 0.5), 0.0)
	assert_true(CellarCatRules.loops(Act.SIT))
	assert_false(CellarCatRules.loops(Act.STRETCH))


func test_he_walks_to_another_spot() -> void:
	for roll : float in [0.0, 0.4, 0.7, 0.99]:
		var spot : int = CellarCatRules.next_spot(3, 1, roll)
		assert_ne(spot, 1)
		assert_true(spot >= 0 and spot < 3)


func test_with_no_spot_yet_any_spot_will_do() -> void:
	assert_eq(CellarCatRules.next_spot(3, -1, 0.0), 0)
	assert_eq(CellarCatRules.next_spot(3, -1, 0.99), 2)
	assert_eq(CellarCatRules.next_spot(1, 0, 0.5), 0)


func test_every_act_has_an_animation_in_the_sheet() -> void:
	var frames : SpriteFrames = load("res://src/resources/sprite_frames/cat_anim.tres")
	for act : int in CellarCatRules.Act.values():
		assert_true(frames.has_animation(CellarCatRules.animation(act)), "no animation for act %d" % act)
	assert_false(frames.get_animation_loop(&"groom"))
	assert_false(frames.get_animation_loop(&"stretch"))


func test_after_a_peek_he_walks_on() -> void:
	assert_eq(CellarCatRules.next_act(Act.PEEK, 0.5), Act.WALK)
	assert_true(CellarCatRules.loops(Act.PEEK))


func test_destinations_cover_rest_peek_and_roam() -> void:
	assert_eq(CellarCatRules.destination(0.0), CellarCatRules.Destination.REST)
	assert_eq(CellarCatRules.destination(0.7), CellarCatRules.Destination.PEEK)
	assert_eq(CellarCatRules.destination(0.99), CellarCatRules.Destination.ROAM)


func test_heading_up_the_floor_shows_his_back() -> void:
	assert_eq(CellarCatRules.walk_animation(Vector2(-5, -40)), &"walk_back")
	assert_eq(CellarCatRules.walk_animation(Vector2(40, -5)), &"walk_left")
	assert_eq(CellarCatRules.walk_animation(Vector2(5, 40)), &"walk_left")


func test_a_far_cat_walks_fewer_screen_pixels() -> void:
	assert_true(CellarCatRules.walk_speed(2.0) < CellarCatRules.walk_speed(3.0))


func test_he_shares_the_customers_layer_only_in_front() -> void:
	assert_eq(CellarCatRules.z_index_at(340.0), 1)
	assert_eq(CellarCatRules.z_index_at(250.0), 0)


func test_a_chase_stays_on_the_floor() -> void:
	var up_the_stairs : Vector2 = CellarCatRules.chase_target(Vector2(102, 79))
	assert_eq(up_the_stairs.y, CellarCatRules.CHASE_FLOOR.position.y)
	assert_eq(CellarCatRules.chase_target(Vector2(300, 320)), Vector2(300, 320))
