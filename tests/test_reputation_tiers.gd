@tool
extends McpTestSuite

## Unit tests for ReputationTiers' lookups and the shipped tier files.

const TiersScript := preload("res://src/brewery/reputation_tiers.gd")
const TierScript := preload("res://src/brewery/reputation_tier.gd")


func suite_name() -> String:
	return "reputation_tiers"


func _tiers() -> Array[ReputationTier]:
	var tiers: Array[ReputationTier] = []
	for min_reputation: int in [0, 15, 30]:
		var tier: ReputationTier = TierScript.new()
		tier.min_reputation = min_reputation
		tiers.append(tier)
	return tiers


func test_tier_for_picks_the_highest_reached_tier() -> void:
	var tiers := _tiers()
	assert_eq(TiersScript.tier_for(0, tiers), tiers[0])
	assert_eq(TiersScript.tier_for(29, tiers), tiers[1])
	assert_eq(TiersScript.tier_for(30, tiers), tiers[2])
	assert_eq(TiersScript.tier_for(500, tiers), tiers[2])


func test_tier_for_is_null_below_every_tier() -> void:
	assert_eq(TiersScript.tier_for(-1, _tiers()), null)


func test_next_tier_is_the_first_one_above() -> void:
	var tiers := _tiers()
	assert_eq(TiersScript.next_tier(0, tiers), tiers[1])
	assert_eq(TiersScript.next_tier(15, tiers), tiers[2])


func test_next_tier_is_null_at_the_top() -> void:
	assert_eq(TiersScript.next_tier(30, _tiers()), null)


func test_a_rise_is_announced_at_once() -> void:
	var tiers := _tiers()
	assert_eq(TiersScript.announced_tier(tiers[0], 15, tiers), tiers[1])


func test_a_small_dip_below_a_tier_keeps_it_announced() -> void:
	var tiers := _tiers()
	assert_eq(TiersScript.announced_tier(tiers[2], 30 - TiersScript.DROP_MARGIN + 1, tiers), tiers[2])


func test_a_drop_past_the_margin_is_announced() -> void:
	var tiers := _tiers()
	assert_eq(TiersScript.announced_tier(tiers[2], 30 - TiersScript.DROP_MARGIN, tiers), tiers[1])
	assert_eq(TiersScript.announced_tier(tiers[2], 3, tiers), tiers[0])


func test_shipped_tiers_start_at_zero_and_are_sorted() -> void:
	var tiers: Array[ReputationTier] = TiersScript.all()
	assert_true(tiers.size() >= 2, "tier files found")
	assert_eq(tiers[0].min_reputation, 0)
	for i: int in range(1, tiers.size()):
		assert_true(tiers[i].min_reputation > tiers[i - 1].min_reputation, "sorted and distinct")
