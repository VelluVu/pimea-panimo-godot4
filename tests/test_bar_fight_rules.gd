@tool
extends McpTestSuite


func suite_name() -> String:
	return "bar_fight_rules"


func _fighter(trigger : CustomerData.BarFightTrigger, chance : float = 1.0, min_bought : int = 0) -> CustomerData:
	var data := CustomerData.new()
	data.bar_fight_trigger = trigger
	data.bar_fight_chance = chance
	data.bar_fight_min_bottles_bought = min_bought
	return data


func test_not_enough_beer_fights_when_turned_away_or_short() -> void:
	var barbarian := _fighter(CustomerData.BarFightTrigger.NOT_ENOUGH_BEER)
	assert_true(BarFightRules.breaks_out(barbarian, 2, 0, 1.0, 0.5), "turned away")
	assert_true(BarFightRules.breaks_out(barbarian, 3, 1, 1.0, 0.5), "got less than wanted")
	assert_false(BarFightRules.breaks_out(barbarian, 2, 2, 1.0, 0.5), "got everything")


func test_bought_many_fights_only_at_the_threshold() -> void:
	var fan := _fighter(CustomerData.BarFightTrigger.BOUGHT_MANY, 1.0, 3)
	assert_true(BarFightRules.breaks_out(fan, 3, 3, 1.0, 0.5))
	assert_false(BarFightRules.breaks_out(fan, 3, 2, 1.0, 0.5))
	assert_false(BarFightRules.breaks_out(fan, 3, 0, 1.0, 0.5), "turned away, bought nothing")


func test_random_needs_a_completed_sale() -> void:
	var fighter := _fighter(CustomerData.BarFightTrigger.RANDOM, 0.2)
	assert_true(BarFightRules.breaks_out(fighter, 1, 1, 1.0, 0.1))
	assert_false(BarFightRules.breaks_out(fighter, 1, 1, 1.0, 0.3), "roll above the chance")
	assert_false(BarFightRules.breaks_out(fighter, 1, 0, 1.0, 0.1), "no sale")


func test_the_perk_multiplier_scales_a_met_trigger() -> void:
	var fan := _fighter(CustomerData.BarFightTrigger.BOUGHT_MANY, 1.0, 3)
	assert_true(BarFightRules.breaks_out(fan, 3, 3, 0.75, 0.7))
	assert_false(BarFightRules.breaks_out(fan, 3, 3, 0.75, 0.8))


func test_a_peaceful_customer_never_fights() -> void:
	var calm := _fighter(CustomerData.BarFightTrigger.NOT_ENOUGH_BEER, 0.0)
	assert_false(BarFightRules.breaks_out(calm, 3, 0, 1.0, 0.0))
