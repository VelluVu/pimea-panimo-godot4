@tool
extends McpTestSuite

## Unit tests for ReputationRules: diminishing gains, the raid penalty and fame effects.

const RulesScript := preload("res://src/brewery/reputation_rules.gd")
const TierScript := preload("res://src/brewery/reputation_tier.gd")


func suite_name() -> String:
	return "reputation_rules"


func test_gain_is_full_at_zero_reputation() -> void:
	assert_eq(RulesScript.scaled_gain(10, 0), 10)


func test_gain_is_halved_at_the_soft_cap() -> void:
	assert_eq(RulesScript.scaled_gain(10, roundi(RulesScript.GAIN_SOFT_CAP)), 5)


func test_gain_never_rounds_down_to_zero() -> void:
	assert_eq(RulesScript.scaled_gain(1, 1000), 1)


func test_losses_are_not_scaled() -> void:
	assert_eq(RulesScript.scaled_gain(-6, 200), -6)
	assert_eq(RulesScript.scaled_gain(0, 200), 0)


func test_apply_floors_at_zero() -> void:
	assert_eq(RulesScript.apply(3, -10), 0)


func test_apply_adds_the_scaled_gain() -> void:
	assert_eq(RulesScript.apply(100, 10), 105)


func test_raid_penalty_is_a_share_of_reputation() -> void:
	assert_eq(RulesScript.raid_penalty(40, 1.0), 10)


func test_raid_penalty_is_capped() -> void:
	assert_eq(RulesScript.raid_penalty(120, 3.0), RulesScript.RAID_PENALTY_MAX)


func _tier(raid_threshold_penalty: int, daily_decay_percent: float) -> ReputationTier:
	var tier: ReputationTier = TierScript.new()
	tier.raid_threshold_penalty = raid_threshold_penalty
	tier.daily_decay_percent = daily_decay_percent
	return tier


func test_fame_lowers_the_raid_threshold() -> void:
	assert_eq(RulesScript.raid_threshold(100, _tier(10, 0.0)), 90)


func test_raid_threshold_never_drops_below_one() -> void:
	assert_eq(RulesScript.raid_threshold(5, _tier(10, 0.0)), 1)


func test_no_tier_leaves_the_threshold_alone() -> void:
	assert_eq(RulesScript.raid_threshold(100, null), 100)


func test_daily_decay_is_a_share_of_reputation() -> void:
	assert_eq(RulesScript.daily_decay(150, _tier(0, 0.04)), 6)
	assert_eq(RulesScript.daily_decay(150, _tier(0, 0.0)), 0)
	assert_eq(RulesScript.daily_decay(150, null), 0)
