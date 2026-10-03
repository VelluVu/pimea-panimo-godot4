@tool
extends McpTestSuite

## Unit tests for ReputationTierText: the top bar's reputation tooltip.

const ReputationTierTextScript := preload("res://src/ui/reputation_tier_text.gd")


func suite_name() -> String:
	return "reputation_tier_text"


func _tier(tier_name : String, min_reputation : int) -> ReputationTier:
	var tier := ReputationTier.new()
	tier.tier_name = tier_name
	tier.min_reputation = min_reputation
	tier.description = "Kuvaus"
	return tier


func test_shows_value_description_and_next_tier() -> void:
	var text : String = ReputationTierTextScript.tooltip(42, _tier("Tuntematon", 0), _tier("Kylän puheenaihe", 60))
	assert_true(text.contains("Maine: 42"))
	assert_true(text.contains("Kuvaus"))
	assert_true(text.contains("Kylän puheenaihe (60 mainetta)"))


func test_top_tier_says_so() -> void:
	assert_true(ReputationTierTextScript.tooltip(500, _tier("Legenda", 400), null).contains("Korkein maine"))


func test_fame_costs_are_listed_only_when_set() -> void:
	var tier := _tier("Legenda", 400)
	assert_false(ReputationTierTextScript.tooltip(500, tier, null).contains("ratsiakynnys"))
	tier.raid_threshold_penalty = 10
	tier.daily_decay_percent = 0.05
	var text : String = ReputationTierTextScript.tooltip(500, tier, null)
	assert_true(text.contains("ratsiakynnys -10"))
	assert_true(text.contains("5 %"))
