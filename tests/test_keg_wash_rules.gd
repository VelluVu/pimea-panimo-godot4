@tool
extends McpTestSuite

const RulesScript := preload("res://src/brewery/keg_wash/keg_wash_rules.gd")
const TunnelScript := preload("res://src/brewery/keg_wash/keg_tunnel.gd")


func suite_name() -> String:
	return "keg_wash_rules"


func test_salmiakki_needs_a_fast_stroke() -> void:
	assert_eq(RulesScript.scrub_work(KegWashSpot.Kind.SALMIAKKI, 10.0, 100.0), 0.0)
	assert_eq(RulesScript.scrub_work(KegWashSpot.Kind.SALMIAKKI, 10.0, 400.0), 10.0)


func test_a_still_brush_scrubs_nothing() -> void:
	assert_eq(RulesScript.scrub_work(KegWashSpot.Kind.YEAST, 1.0, 10.0), 0.0)
	assert_eq(RulesScript.scrub_work(KegWashSpot.Kind.YEAST, 5.0, 100.0), 5.0)


func test_cleanliness_weighs_scrubbing_most() -> void:
	assert_true(is_equal_approx(RulesScript.cleanliness(1.0, 0.0, 0.0), 0.6))
	assert_true(is_equal_approx(RulesScript.cleanliness(1.0, 1.0, 1.0), 1.0))
	assert_true(is_equal_approx(RulesScript.cleanliness(0.0, 0.0, 0.5), 0.1))


func test_a_keg_holds_three_to_five_things_inside_the_opening() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value : int in 40:
		rng.seed = seed_value
		var spots : Array[KegWashSpot] = RulesScript.roll_spots(rng)
		assert_true(spots.size() >= RulesScript.MIN_SPOTS and spots.size() <= RulesScript.MAX_SPOTS)
		for spot : KegWashSpot in spots:
			assert_true(TunnelScript.reach(spot.position) <= TunnelScript.SPOT_REACH + 0.001)


func test_the_hat_and_the_coconut_turn_up_once_at_most() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value : int in 200:
		rng.seed = seed_value
		var hats : int = 0
		var coconuts : int = 0
		for spot : KegWashSpot in RulesScript.roll_spots(rng):
			hats += 1 if spot.kind == KegWashSpot.Kind.HAT else 0
			coconuts += 1 if spot.kind == KegWashSpot.Kind.COCONUT else 0
		assert_true(hats <= 1 and coconuts <= 1)
