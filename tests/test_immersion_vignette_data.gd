@tool
extends McpTestSuite

## Unit tests for ImmersionVignetteData.pick_weight(): the seasonal weights.

const VignetteScript := preload("res://src/events/immersion_vignette_data.gd")


func suite_name() -> String:
	return "immersion_vignette_data"


func _vignette(weight : float, halloween_weight : float = -1.0) -> ImmersionVignetteData:
	var vignette : ImmersionVignetteData = VignetteScript.new()
	vignette.weight = weight
	vignette.halloween_weight = halloween_weight
	return vignette


func test_halloween_uses_the_seasonal_weight() -> void:
	assert_eq(_vignette(0.7, 4.0).pick_weight(true), 4.0)
	assert_eq(_vignette(0.7, 4.0).pick_weight(false), 0.7)


func test_without_a_seasonal_weight_the_year_round_one_holds() -> void:
	assert_eq(_vignette(0.7).pick_weight(true), 0.7)


func test_the_bats_are_commoner_at_halloween() -> void:
	var bats : ImmersionVignetteData = load("res://src/resources/immersion_vignettes/bats.tres")
	assert_true(bats.pick_weight(true) > bats.pick_weight(false))


func test_a_christmas_vignette_plays_only_at_christmas() -> void:
	var tontut := _vignette(1.5)
	tontut.only_in_season = SeasonRules.Season.CHRISTMAS
	assert_eq(tontut.pick_weight(false, SeasonRules.Season.CHRISTMAS), 1.5)
	assert_eq(tontut.pick_weight(false, SeasonRules.Season.NONE), 0.0)
	assert_eq(tontut.pick_weight(true, SeasonRules.Season.HALLOWEEN), 0.0)
