@tool
extends McpTestSuite

## Unit tests for KegRules: only a nearly full batch counts as a keg for the bar goal.

const KegRulesScript := preload("res://src/brewery/keg_rules.gd")


func suite_name() -> String:
	return "keg_rules"


func test_a_fresh_batch_is_a_full_keg() -> void:
	# A fresh batch is 45 servings after bottling loss.
	assert_true(KegRulesScript.is_full_keg(45))
	assert_true(KegRulesScript.is_full_keg(KegRulesScript.MIN_SERVINGS))


func test_a_drawn_batch_is_not_a_full_keg() -> void:
	assert_false(KegRulesScript.is_full_keg(KegRulesScript.MIN_SERVINGS - 1))
	assert_false(KegRulesScript.is_full_keg(0))


func test_a_season_starts_with_clean_kegs() -> void:
	var kegs : Array[float] = KegRulesScript.starting_kegs()
	assert_eq(kegs.size(), KegRulesScript.START_KEGS)
	assert_eq(KegRulesScript.dirty_count(kegs), 0)


func test_a_brew_takes_the_cleanest_keg() -> void:
	var kegs : Array[float] = [0.0, 0.7, 0.3]
	assert_eq(KegRulesScript.take_cleanest(kegs), 0.7)
	assert_eq(kegs.size(), 2)
	assert_false(kegs.has(0.7))


func test_a_brew_without_kegs_gets_a_clean_one() -> void:
	var kegs : Array[float] = []
	assert_eq(KegRulesScript.take_cleanest(kegs), KegRulesScript.CLEAN)


func test_washing_cleans_the_dirtiest_keg() -> void:
	var kegs : Array[float] = [1.0, 0.0, 0.5]
	assert_true(KegRulesScript.wash_dirtiest(kegs, 0.9))
	assert_eq(kegs, [1.0, 0.9, 0.5] as Array[float])


func test_a_poor_wash_never_makes_a_keg_dirtier() -> void:
	var kegs : Array[float] = [0.6]
	assert_true(KegRulesScript.wash_dirtiest(kegs, 0.2))
	assert_eq(kegs[0], 0.6)


func test_nothing_to_wash_when_every_keg_is_clean() -> void:
	var kegs : Array[float] = [1.0, 1.0]
	assert_false(KegRulesScript.wash_dirtiest(kegs, 1.0))
	assert_false(KegRulesScript.wash_dirtiest([] as Array[float], 1.0))


func test_dirty_count_counts_every_unfinished_wash() -> void:
	assert_eq(KegRulesScript.dirty_count([0.0, 0.99, 1.0] as Array[float]), 2)


func test_the_spare_kegs_have_no_taps() -> void:
	assert_eq(KegRulesScript.tap_count(KegRulesScript.START_KEGS), KegRulesScript.START_TAPS)
	assert_eq(KegRulesScript.tap_count(12), 12 - KegRulesScript.SPARE_KEGS)
	assert_eq(KegRulesScript.tap_count(0), 1)
