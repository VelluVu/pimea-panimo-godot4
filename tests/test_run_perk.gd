@tool
extends McpTestSuite

## Unit tests for RunPerk's pure presentational helpers: get_stat_summary()
## (only non-neutral fields shown) and the tier label/color lookups added
## for LevelUpWindow's rarity display (see PerkRegistry.TIER_WEIGHTS).


func suite_name() -> String:
	return "run_perk"


func test_stat_summary_is_empty_for_a_fully_neutral_perk() -> void:
	var perk := RunPerk.new()
	assert_eq(perk.get_stat_summary(), "")


func test_stat_summary_only_lists_non_neutral_fields() -> void:
	var perk := RunPerk.new()
	perk.quality_bonus = 0.15
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_QUALITY_STAT_STRING % "+15 %")


func test_stat_summary_shows_multiplicative_multipliers_as_times() -> void:
	var perk := RunPerk.new()
	perk.reputation_gain_multiplier = 1.3
	perk.tip_income_multiplier = 1.2
	var expected := StringContainer.PERK_REPUTATION_STAT_STRING % "×1.30" + "
" + StringContainer.PERK_TIP_STAT_STRING % "×1.20"
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_shows_a_reduction_below_one() -> void:
	var perk := RunPerk.new()
	perk.ingredient_price_multiplier = 0.9
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_INGREDIENT_PRICE_STAT_STRING % "×0.90")


func test_stat_summary_shows_additive_multipliers_as_plus_percent() -> void:
	var perk := RunPerk.new()
	perk.tip_income_multiplier = 1.2
	perk.spawn_interval_multiplier = 0.85
	perk.stacks_additively = true
	var expected := StringContainer.PERK_TIP_STAT_STRING % "+20 %" + "
" + StringContainer.PERK_SPAWN_INTERVAL_STAT_STRING % "-15 %"
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_shows_chances_and_counts_as_added() -> void:
	var perk := RunPerk.new()
	perk.ingredient_refund_chance = 0.24
	perk.extra_raid_strikes = 1
	perk.raid_hidden_batch_count = 2
	var expected := StringContainer.PERK_REFUND_CHANCE_STAT_STRING % "+24 %" + "
" 		+ StringContainer.PERK_EXTRA_RAID_STRIKES_STAT_STRING % "+1" + "
" 		+ StringContainer.PERK_RAID_HIDDEN_BATCH_STAT_STRING % "+2"
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_is_empty_for_a_neutral_additive_perk() -> void:
	var perk := RunPerk.new()
	perk.stacks_additively = true
	assert_eq(perk.get_stat_summary(), "")


## Unit tests for RunPerk.combine_stacking() — the pure combination math
## behind Brewery.get_reputation_gain_multiplier() and its siblings,
## deliberately static (see its own docstring) so it's testable here
## without a live Brewery.
func test_combine_stacking_multiplies_by_default() -> void:
	var perk_a := RunPerk.new()
	perk_a.tip_income_multiplier = 1.2
	var perk_b := RunPerk.new()
	perk_b.tip_income_multiplier = 1.2

	var result := RunPerk.combine_stacking(1.0, [perk_a, perk_b], func(p: RunPerk) -> float: return p.tip_income_multiplier)
	assert_true(is_equal_approx(result, 1.44), "1.2 * 1.2 should compound to 1.44")


func test_combine_stacking_adds_when_flagged_additive() -> void:
	var perk_a := RunPerk.new()
	perk_a.tip_income_multiplier = 1.2
	perk_a.stacks_additively = true
	var perk_b := RunPerk.new()
	perk_b.tip_income_multiplier = 1.2
	perk_b.stacks_additively = true

	var result := RunPerk.combine_stacking(1.0, [perk_a, perk_b], func(p: RunPerk) -> float: return p.tip_income_multiplier)
	assert_true(is_equal_approx(result, 1.4), "two +20% additive picks should sum to a flat +40%, not compound")


func test_combine_stacking_mixes_both_modes_in_one_total() -> void:
	var multiplicative := RunPerk.new()
	multiplicative.tip_income_multiplier = 1.2
	var additive := RunPerk.new()
	additive.tip_income_multiplier = 1.2
	additive.stacks_additively = true

	# Multiplicative perks apply to the base first (1.0 * 1.2 = 1.2),
	# then every additive perk's delta is summed on top (+0.2).
	var result := RunPerk.combine_stacking(1.0, [multiplicative, additive], func(p: RunPerk) -> float: return p.tip_income_multiplier)
	assert_true(is_equal_approx(result, 1.4))


func test_combine_stacking_respects_a_non_neutral_base() -> void:
	var perk := RunPerk.new()
	perk.reputation_gain_multiplier = 1.1
	perk.stacks_additively = true

	# The base (1.5 here) is the starting point: the additive perk's +10%
	# lands on top of it, not on a fresh 1.0.
	var result := RunPerk.combine_stacking(1.5, [perk], func(p: RunPerk) -> float: return p.reputation_gain_multiplier)
	assert_true(is_equal_approx(result, 1.6))


func test_tier_label_and_color_for_each_tier() -> void:
	var perk := RunPerk.new()

	perk.tier = RunPerk.Tier.COMMON
	assert_eq(perk.get_tier_label(), StringContainer.PERK_TIER_COMMON)
	assert_eq(perk.get_tier_color(), RunPerk.TIER_COLOR_COMMON)

	perk.tier = RunPerk.Tier.RARE
	assert_eq(perk.get_tier_label(), StringContainer.PERK_TIER_RARE)
	assert_eq(perk.get_tier_color(), RunPerk.TIER_COLOR_RARE)

	perk.tier = RunPerk.Tier.LEGENDARY
	assert_eq(perk.get_tier_label(), StringContainer.PERK_TIER_LEGENDARY)
	assert_eq(perk.get_tier_color(), RunPerk.TIER_COLOR_LEGENDARY)


func test_strength_copy_moves_stats_part_way_from_neutral() -> void:
	var perk := RunPerk.new()
	perk.perk_name = "Vinkit"
	perk.peak_speed_multiplier = 0.8
	perk.quality_bonus = 0.2
	perk.extra_counter_slots = 3
	var half : RunPerk = perk.strength_copy(0.5)
	assert_true(is_equal_approx(half.peak_speed_multiplier, 0.9))
	assert_true(is_equal_approx(half.quality_bonus, 0.1))
	assert_eq(half.extra_counter_slots, 1, "counts round down")
	assert_eq(half.perk_name, "Vinkit")
	assert_true(is_equal_approx(perk.peak_speed_multiplier, 0.8), "the template is untouched")
