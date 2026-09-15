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
