@tool
extends McpTestSuite

## Unit tests for GoalRules, the goals system's pure decisions: outcomes, which
## slots an event advances and replacement picking. DailyGoalData supplies the
## kinds, its avoid type and its BREW_STYLE matching.

const RulesScript := preload("res://src/systems/goals/goal_rules.gd")


func suite_name() -> String:
	return "goal_rules"


func _goal(goal_type : DailyGoalData.GoalType, target : int = 10) -> DailyGoalData:
	var goal := DailyGoalData.new()
	goal.goal_type = goal_type
	goal.target_amount = target
	return goal


func _goals(list : Array) -> Array[GoalData]:
	var typed : Array[GoalData] = []
	for goal in list:
		typed.append(goal)
	return typed


func test_an_achieve_goal_succeeds_at_or_past_its_target() -> void:
	var goal := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	assert_eq(RulesScript.check_outcome(goal, 9, 10), RulesScript.Outcome.PENDING)
	assert_eq(RulesScript.check_outcome(goal, 10, 10), RulesScript.Outcome.SUCCEEDED)
	assert_eq(RulesScript.check_outcome(goal, 25, 10), RulesScript.Outcome.SUCCEEDED)

func test_an_avoid_goal_fails_only_when_progress_passes_the_target() -> void:
	var goal := _goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX)
	assert_eq(RulesScript.check_outcome(goal, 2, 2), RulesScript.Outcome.PENDING, "reaching the limit is still allowed")
	assert_eq(RulesScript.check_outcome(goal, 3, 2), RulesScript.Outcome.FAILED)

func test_an_avoid_goal_never_succeeds_mid_day() -> void:
	var goal := _goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX)
	assert_eq(RulesScript.check_outcome(goal, 0, 2), RulesScript.Outcome.PENDING)

func test_matching_slots_finds_every_goal_of_the_type() -> void:
	var goals := _goals([_goal(DailyGoalData.GoalType.SELL_BOTTLES), _goal(DailyGoalData.GoalType.EARN_MONEY), _goal(DailyGoalData.GoalType.SELL_BOTTLES)])
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.SELL_BOTTLES), [0, 2])
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.SHIP_TO_BAR), [])

func test_matching_slots_skips_empty_slots() -> void:
	var goals : Array[GoalData] = [null, _goal(DailyGoalData.GoalType.EARN_MONEY), null]
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.EARN_MONEY), [1])

func test_brew_style_goals_only_match_their_own_style() -> void:
	var ipa := _goal(DailyGoalData.GoalType.BREW_STYLE)
	ipa.target_style = BeerStyle.Style.IPA
	var helles := _goal(DailyGoalData.GoalType.BREW_STYLE)
	helles.target_style = BeerStyle.Style.HELLES
	var goals := _goals([ipa, helles])
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.BREW_STYLE, BeerStyle.Style.HELLES), [1])
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.BREW_STYLE, BeerStyle.Style.KOTIKALJA), [])

func test_other_types_ignore_the_required_style() -> void:
	var goals := _goals([_goal(DailyGoalData.GoalType.SELL_BOTTLES)])
	assert_eq(RulesScript.matching_slots(goals, DailyGoalData.GoalType.SELL_BOTTLES, BeerStyle.Style.IPA), [0])

func test_a_new_goal_never_shares_a_type_with_an_active_one() -> void:
	var a := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var b := _goal(DailyGoalData.GoalType.EARN_MONEY)
	var c := _goal(DailyGoalData.GoalType.SHIP_TO_BAR)
	var pool := _goals([a, b, c])
	for attempt : int in range(20):
		assert_eq(RulesScript.pick_new_goal(pool, _goals([a, b])), c)

func test_tiers_of_the_same_goal_never_show_together() -> void:
	var easy := _goal(DailyGoalData.GoalType.EARN_MONEY)
	var hard := _goal(DailyGoalData.GoalType.EARN_MONEY)
	var other := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var pool := _goals([easy, hard, other])
	for attempt : int in range(20):
		assert_eq(RulesScript.pick_new_goal(pool, _goals([easy])), other)

func test_empty_slots_do_not_block_any_type() -> void:
	var a := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var no_goal : Array[GoalData] = [null, null, null]
	assert_eq(RulesScript.pick_new_goal(_goals([a]), no_goal), a)

func test_no_new_goal_when_every_pool_type_is_active() -> void:
	var a := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var same_type := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	assert_eq(RulesScript.pick_new_goal(_goals([a, same_type]), _goals([a])), null)

func test_no_new_goal_from_an_empty_pool() -> void:
	assert_eq(RulesScript.pick_new_goal(_goals([]), _goals([])), null)

