@tool
extends McpTestSuite

## Unit tests for FirstBrewRules: the season's first batch of a style.

const FirstBrewRulesScript := preload("res://src/brewing/first_brew_rules.gd")


func suite_name() -> String:
	return "first_brew_rules"


func _style(reputation_change : int) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.reputation_change = reputation_change
	return beer_style


func test_a_demanding_style_pays_more_xp() -> void:
	assert_eq(FirstBrewRulesScript.xp_bonus(_style(2)), 20)
	assert_eq(FirstBrewRulesScript.xp_bonus(_style(6)), 60)


func test_a_style_that_costs_reputation_still_pays_some_xp() -> void:
	assert_eq(FirstBrewRulesScript.xp_bonus(_style(-1)), FirstBrewRulesScript.XP_PER_STYLE_REPUTATION)


func test_only_a_novelty_sells_at_a_premium() -> void:
	assert_eq(FirstBrewRulesScript.price_multiplier(false), 1.0)
	assert_eq(FirstBrewRulesScript.price_multiplier(true), 1.0 + FirstBrewRulesScript.NOVELTY_PRICE_BONUS)
