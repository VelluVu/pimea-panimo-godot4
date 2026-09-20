@tool
extends McpTestSuite

## Unit tests for DailyGoalRules, the pure goal decisions behind
## DailyGoalManager: outcomes, which slots an event advances, resolution
## effects and replacement picking. Loaded by path so the suite always runs the
## script as it is on disk.

const RulesScript := preload("res://src/classes/daily_goal_rules.gd")


func suite_name() -> String:
	return "daily_goal_rules"


func _goal(goal_type : DailyGoalData.GoalType, target : int = 10) -> DailyGoalData:
	var goal := DailyGoalData.new()
	goal.goal_type = goal_type
	goal.target_amount = target
	return goal


func _goals(list : Array) -> Array[DailyGoalData]:
	var typed : Array[DailyGoalData] = []
	for goal in list:
		typed.append(goal)
	return typed


func test_only_unhappy_customers_is_an_avoid_goal() -> void:
	assert_true(RulesScript.is_avoid_type(_goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX)))
	assert_false(RulesScript.is_avoid_type(_goal(DailyGoalData.GoalType.SELL_BOTTLES)))
	assert_false(RulesScript.is_avoid_type(_goal(DailyGoalData.GoalType.EARN_MONEY)))


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
	var goals : Array[DailyGoalData] = [null, _goal(DailyGoalData.GoalType.EARN_MONEY), null]
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


func test_reputation_progress_is_the_gain_since_the_baseline() -> void:
	assert_eq(RulesScript.reputation_progress(30, 10), 20)
	assert_eq(RulesScript.reputation_progress(10, 10), 0)


func test_reputation_progress_never_goes_negative() -> void:
	assert_eq(RulesScript.reputation_progress(4, 10), 0)


func _reward_goal() -> DailyGoalData:
	var goal := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	goal.reward_money = 20
	goal.reward_reputation = 5
	goal.reward_xp = 30
	goal.penalty_reputation = 3
	goal.penalty_risk = 4
	return goal


func test_success_pays_money_reputation_and_xp_but_no_risk() -> void:
	var effects : Dictionary = RulesScript.resolution_effects(_reward_goal(), true, true, 1)
	assert_eq(effects, {"money": 20, "reputation": 5, "xp": 30, "risk": 0})


func test_failure_costs_reputation_and_risk_but_pays_nothing() -> void:
	var effects : Dictionary = RulesScript.resolution_effects(_reward_goal(), false, true, 1)
	assert_eq(effects, {"money": 0, "reputation": -3, "xp": 0, "risk": 4})


func test_a_good_faith_failure_changes_nothing() -> void:
	var effects : Dictionary = RulesScript.resolution_effects(_reward_goal(), false, false, 1)
	assert_eq(effects, {"money": 0, "reputation": 0, "xp": 0, "risk": 0})


func test_success_rewards_scale_with_the_day() -> void:
	var goal := _reward_goal()
	goal.scales_with_day = true
	goal.target_scale_per_day = 0.5
	var effects : Dictionary = RulesScript.resolution_effects(goal, true, true, 3)
	# Day 3 is 1 + 0.5 * 2 = 2x.
	assert_eq(effects, {"money": 40, "reputation": 10, "xp": 60, "risk": 0})


func test_a_new_goal_is_never_one_already_active() -> void:
	var a := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var b := _goal(DailyGoalData.GoalType.EARN_MONEY)
	var c := _goal(DailyGoalData.GoalType.SHIP_TO_BAR)
	var pool := _goals([a, b, c])
	for attempt : int in range(20):
		assert_eq(RulesScript.pick_new_goal(pool, _goals([a, b])), c)


func test_no_new_goal_when_every_pool_goal_is_active() -> void:
	var a := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	assert_eq(RulesScript.pick_new_goal(_goals([a]), _goals([a])), null)


func test_no_new_goal_from_an_empty_pool() -> void:
	assert_eq(RulesScript.pick_new_goal(_goals([]), _goals([])), null)
