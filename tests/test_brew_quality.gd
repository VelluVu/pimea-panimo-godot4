@tool
extends McpTestSuite

## Unit tests for BrewQuality: range precision and the hop bonuses, on hand-built mixtures.

const BrewQualityScript := preload("res://src/brewing/brew_quality.gd")
const BrewMixtureScript := preload("res://src/brewing/brew_mixture.gd")


func suite_name() -> String:
	return "brew_quality"


func _make_mixture(alpha : float, beta : float, hop_count : int) -> BrewMixtureScript:
	var mixture := BrewMixtureScript.new()
	mixture.alpha_acids = alpha
	mixture.beta_acids = beta
	for id in hop_count:
		mixture.hop_ids[id] = true
	return mixture


func test_range_precision_is_perfect_at_center() -> void:
	assert_eq(BrewQualityScript.range_precision(20, 10, 30), 1.0)


func test_range_precision_is_zero_at_edges() -> void:
	assert_eq(BrewQualityScript.range_precision(10, 10, 30), 0.0)
	assert_eq(BrewQualityScript.range_precision(30, 10, 30), 0.0)


func test_range_precision_is_clamped_outside_range() -> void:
	assert_eq(BrewQualityScript.range_precision(5, 10, 30), 0.0)


func test_range_precision_handles_degenerate_range() -> void:
	assert_eq(BrewQualityScript.range_precision(999, 10, 10), 1.0)


func test_hop_balance_bonus_is_zero_without_both_acids() -> void:
	assert_eq(BrewQualityScript.hop_balance_bonus(_make_mixture(0.0, 5.0, 1)), 0.0)
	assert_eq(BrewQualityScript.hop_balance_bonus(_make_mixture(5.0, 0.0, 1)), 0.0)


func test_hop_balance_bonus_peaks_when_acids_match() -> void:
	assert_true(is_equal_approx(BrewQualityScript.hop_balance_bonus(_make_mixture(4.0, 4.0, 1)), BrewQualityScript.HOP_BALANCE_WEIGHT))


func test_hop_diversity_bonus_is_capped() -> void:
	assert_eq(BrewQualityScript.hop_diversity_bonus(_make_mixture(1.0, 1.0, 1)), 0.0)
	assert_eq(BrewQualityScript.hop_diversity_bonus(_make_mixture(1.0, 1.0, 20)), BrewQualityScript.HOP_DIVERSITY_MAX)


func test_multiplier_is_neutral_at_neutral_precision_without_bonuses() -> void:
	var mixture := _make_mixture(0.0, 0.0, 0)
	assert_true(is_equal_approx(BrewQualityScript.multiplier(mixture, BrewQualityScript.NEUTRAL_PRECISION, 0.0, false), 1.0))


func test_multiplier_is_clamped_and_rewards_flavor_match() -> void:
	var mixture := _make_mixture(0.0, 0.0, 0)
	assert_true(BrewQualityScript.multiplier(mixture, 1.0, 0.0, true) > BrewQualityScript.multiplier(mixture, 1.0, 0.0, false))
	assert_true(BrewQualityScript.multiplier(mixture, 1.0, 5.0, true) <= BrewQualityScript.MAX_MULTIPLIER)
