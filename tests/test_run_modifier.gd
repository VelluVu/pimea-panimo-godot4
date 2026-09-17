@tool
extends McpTestSuite

## Unit tests for RunModifier.get_stat_summary(), including the
## quality_bonus/reputation_gain_multiplier/tip_income_multiplier fields
## added so a modifier can trade against those axes too, not just LVV
## threshold vs. ingredient price (see "Tunnettu nimi" for a modifier that
## actually uses them).


func suite_name() -> String:
	return "run_modifier"


func test_stat_summary_is_empty_for_a_fully_neutral_modifier() -> void:
	var modifier := RunModifier.new()
	assert_eq(modifier.get_stat_summary(), "")


func test_stat_summary_lists_lvv_and_price_with_signed_percent() -> void:
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 0.85
	modifier.ingredient_price_multiplier = 1.4
	var expected := StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING % -15 + "\n" + StringContainer.MODIFIER_INGREDIENT_PRICE_STAT_STRING % 40
	assert_eq(modifier.get_stat_summary(), expected)


func test_stat_summary_includes_the_shared_perk_style_stat_lines() -> void:
	var modifier := RunModifier.new()
	modifier.reputation_gain_multiplier = 1.25
	var expected := StringContainer.PERK_REPUTATION_STAT_STRING % 25
	assert_eq(modifier.get_stat_summary(), expected)


func test_stat_summary_combines_all_non_neutral_fields_in_declared_order() -> void:
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 0.85
	modifier.reputation_gain_multiplier = 1.25
	var expected := StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING % -15 + "\n" + StringContainer.PERK_REPUTATION_STAT_STRING % 25
	assert_eq(modifier.get_stat_summary(), expected)


## Unit tests for get_difficulty_score() — see RunModifierRegistry.
## get_run_start_modifiers() and LeaderboardManager.calculate_score() for
## where this feeds into.
func test_difficulty_score_is_zero_for_a_fully_neutral_modifier() -> void:
	var modifier := RunModifier.new()
	assert_eq(modifier.get_difficulty_score(), 0.0)


func test_difficulty_score_is_positive_when_lvv_threshold_is_lower() -> void:
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 0.7
	assert_true(is_equal_approx(modifier.get_difficulty_score(), 0.3))


func test_difficulty_score_is_negative_when_lvv_threshold_is_higher() -> void:
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 1.3
	assert_true(is_equal_approx(modifier.get_difficulty_score(), -0.3))


func test_difficulty_score_is_positive_when_ingredient_price_is_higher() -> void:
	var modifier := RunModifier.new()
	modifier.ingredient_price_multiplier = 1.7
	assert_true(is_equal_approx(modifier.get_difficulty_score(), 0.7))


func test_difficulty_score_nets_offsetting_fields_toward_zero() -> void:
	# A higher LVV threshold (easier) fully offset by an equal ingredient
	# price hike (harder) should net to roughly neutral overall difficulty.
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 1.5
	modifier.ingredient_price_multiplier = 1.5
	assert_true(is_equal_approx(modifier.get_difficulty_score(), 0.0))
