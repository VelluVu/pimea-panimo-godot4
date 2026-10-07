@tool
extends McpTestSuite

const PopupTierRulesScript := preload("res://src/customers/popup_tier_rules.gd")


func suite_name() -> String:
	return "popup_tier_rules"


func test_no_tip_is_never_loud() -> void:
	assert_eq(PopupTierRulesScript.tip_tier(0.0, 5.0, true), PopupTierRulesScript.Tier.NORMAL)


func test_tip_tier_follows_its_share_of_the_price() -> void:
	assert_eq(PopupTierRulesScript.tip_tier(2.4, 5.0, false), PopupTierRulesScript.Tier.NORMAL)
	assert_eq(PopupTierRulesScript.tip_tier(2.5, 5.0, false), PopupTierRulesScript.Tier.BIG)
	assert_eq(PopupTierRulesScript.tip_tier(5.0, 5.0, false), PopupTierRulesScript.Tier.CRITICAL)


func test_doubled_tip_is_always_critical() -> void:
	assert_eq(PopupTierRulesScript.tip_tier(0.4, 10.0, true), PopupTierRulesScript.Tier.CRITICAL)


func test_free_sale_does_not_divide_by_zero() -> void:
	assert_eq(PopupTierRulesScript.tip_tier(1.0, 0.0, false), PopupTierRulesScript.Tier.CRITICAL)


func test_quality_tier_uses_the_excellent_and_masterful_bars() -> void:
	assert_eq(PopupTierRulesScript.quality_tier(1.09, 3), PopupTierRulesScript.Tier.NORMAL)
	assert_eq(PopupTierRulesScript.quality_tier(1.1, 3), PopupTierRulesScript.Tier.BIG)
	assert_eq(PopupTierRulesScript.quality_tier(1.3, 3), PopupTierRulesScript.Tier.CRITICAL)


func test_penalty_is_never_loud() -> void:
	assert_eq(PopupTierRulesScript.quality_tier(1.5, 0), PopupTierRulesScript.Tier.NORMAL)
	assert_eq(PopupTierRulesScript.quality_tier(1.5, -2), PopupTierRulesScript.Tier.NORMAL)
