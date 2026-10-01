@tool
extends McpTestSuite

## Unit tests for this game's daily goal maths (DailyGoalRules: reputation
## progress and resolution effects) and DailyGoalData's avoid type. The generic
## outcome, matching and picking rules are in test_goal_rules.gd.

const RulesScript := preload("res://src/progression/daily_goal_rules.gd")


func suite_name() -> String:
	return "daily_goal_rules"


func _goal(goal_type : DailyGoalData.GoalType, target : int = 10) -> DailyGoalData:
	var goal := DailyGoalData.new()
	goal.goal_type = goal_type
	goal.target_amount = target
	return goal



func test_only_unhappy_customers_is_an_avoid_goal() -> void:
	assert_true(_goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX).is_avoid())
	assert_false(_goal(DailyGoalData.GoalType.SELL_BOTTLES).is_avoid())
	assert_false(_goal(DailyGoalData.GoalType.EARN_MONEY).is_avoid())


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