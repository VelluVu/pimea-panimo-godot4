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
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_QUALITY_STAT_STRING % 15)


func test_stat_summary_combines_multiple_non_neutral_fields() -> void:
	var perk := RunPerk.new()
	perk.reputation_gain_multiplier = 1.3
	perk.tip_income_multiplier = 1.2
	var expected := StringContainer.PERK_REPUTATION_STAT_STRING % 30 + "\n" + StringContainer.PERK_TIP_STAT_STRING % 20
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_includes_raid_threshold_and_distribution_income() -> void:
	var perk := RunPerk.new()
	perk.raid_threshold_multiplier = 1.25
	perk.distribution_income_multiplier = 1.4
	var expected := StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING % 25 + "\n" + StringContainer.PERK_DISTRIBUTION_STAT_STRING % 40
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_includes_ingredient_price() -> void:
	var perk := RunPerk.new()
	perk.ingredient_price_multiplier = 0.9
	assert_eq(perk.get_stat_summary(), StringContainer.MODIFIER_INGREDIENT_PRICE_STAT_STRING % -10)


func test_stat_summary_includes_brew_yield() -> void:
	var perk := RunPerk.new()
	perk.brew_yield_multiplier = 1.15
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_YIELD_STAT_STRING % 15)


func test_stat_summary_includes_ingredient_refund_chance() -> void:
	var perk := RunPerk.new()
	perk.ingredient_refund_chance = 0.24
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_REFUND_CHANCE_STAT_STRING % 24)


func test_stat_summary_includes_peak_speed_and_decline_rate() -> void:
	var perk := RunPerk.new()
	perk.peak_speed_multiplier = 0.7
	perk.decline_rate_multiplier = 0.6
	var expected := StringContainer.PERK_PEAK_SPEED_STAT_STRING % -30 + "\n" + StringContainer.PERK_DECLINE_RATE_STAT_STRING % -40
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_includes_spawn_interval() -> void:
	var perk := RunPerk.new()
	perk.spawn_interval_multiplier = 0.85
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_SPAWN_INTERVAL_STAT_STRING % -15)


func test_stat_summary_includes_agentti_and_mafioso_appearance() -> void:
	var perk := RunPerk.new()
	perk.agentti_appearance_multiplier = 0.7
	perk.mafioso_appearance_multiplier = 1.45
	var expected := StringContainer.PERK_AGENTTI_APPEARANCE_STAT_STRING % -30 + "\n" + StringContainer.PERK_MAFIOSO_APPEARANCE_STAT_STRING % 45
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_includes_tip_double_chance() -> void:
	var perk := RunPerk.new()
	perk.tip_double_chance = 0.16
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_TIP_DOUBLE_CHANCE_STAT_STRING % 16)


func test_stat_summary_includes_bar_fight_chance() -> void:
	var perk := RunPerk.new()
	perk.bar_fight_chance_multiplier = 0.5
	assert_eq(perk.get_stat_summary(), StringContainer.PERK_BAR_FIGHT_CHANCE_STAT_STRING % -50)


func test_stat_summary_includes_counter_price_and_group_event_interval() -> void:
	var perk := RunPerk.new()
	perk.counter_price_multiplier = 1.06
	perk.group_event_interval_multiplier = 0.75
	var expected := StringContainer.PERK_COUNTER_PRICE_STAT_STRING % 6 + "\n" + StringContainer.PERK_GROUP_EVENT_INTERVAL_STAT_STRING % -25
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_includes_extra_raid_strikes_and_hidden_batch_count() -> void:
	var perk := RunPerk.new()
	perk.extra_raid_strikes = 1
	perk.raid_hidden_batch_count = 2
	var expected := StringContainer.PERK_EXTRA_RAID_STRIKES_STAT_STRING % 1 + "\n" + StringContainer.PERK_RAID_HIDDEN_BATCH_STAT_STRING % 2
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_flags_additive_stacking() -> void:
	var perk := RunPerk.new()
	perk.tip_income_multiplier = 1.2
	perk.stacks_additively = true
	var expected := StringContainer.PERK_TIP_STAT_STRING % 20 + "\n" + StringContainer.PERK_ADDITIVE_STACKING_HINT
	assert_eq(perk.get_stat_summary(), expected)


func test_stat_summary_omits_additive_hint_for_a_neutral_perk() -> void:
	# A perk with no non-neutral fields set has nothing to flag, even if
	# stacks_additively happens to be true.
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

	# A RunModifier's own multiplier (1.5 here) is the starting point —
	# the additive perk's +10% lands on top of it, not on a fresh 1.0.
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
