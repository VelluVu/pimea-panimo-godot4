@tool
extends McpTestSuite

## Unit tests for GoalStatus: the colour-state and near-miss rules of the goals panel.

const GoalStatusScript := preload("res://src/progression/goal_status.gd")

const ACHIEVE : DailyGoalData.GoalType = DailyGoalData.GoalType.SELL_BOTTLES
const AVOID : DailyGoalData.GoalType = DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX


func suite_name() -> String:
	return "goal_status"


func test_run_day_is_met_at_target_even_when_broke() -> void:
	assert_eq(GoalStatusScript.run_day(30, 30, true), GoalStatusScript.State.MET)


func test_run_day_fails_only_when_money_is_in_danger() -> void:
	assert_eq(GoalStatusScript.run_day(5, 30, true), GoalStatusScript.State.FAILING)
	assert_eq(GoalStatusScript.run_day(5, 30, false), GoalStatusScript.State.PENDING)


func test_run_reputation_money_danger_overrides_met() -> void:
	assert_eq(GoalStatusScript.run_reputation(50, 40, true), GoalStatusScript.State.FAILING)
	assert_eq(GoalStatusScript.run_reputation(50, 40, false), GoalStatusScript.State.MET)
	assert_eq(GoalStatusScript.run_reputation(10, 40, false), GoalStatusScript.State.PENDING)


func test_daily_goal_achieve_is_met_at_target() -> void:
	assert_eq(GoalStatusScript.daily_goal(ACHIEVE, 4, 5), GoalStatusScript.State.PENDING)
	assert_eq(GoalStatusScript.daily_goal(ACHIEVE, 5, 5), GoalStatusScript.State.MET)


func test_daily_goal_avoid_fails_at_the_limit() -> void:
	assert_eq(GoalStatusScript.daily_goal(AVOID, 2, 3), GoalStatusScript.State.PENDING)
	assert_eq(GoalStatusScript.daily_goal(AVOID, 3, 3), GoalStatusScript.State.FAILING)


func test_near_miss_only_for_achieve_goals_between_ratio_and_target() -> void:
	assert_false(GoalStatusScript.is_near_miss(ACHIEVE, 3, 5), "60% is not near")
	assert_true(GoalStatusScript.is_near_miss(ACHIEVE, 4, 5), "80% is near")
	assert_false(GoalStatusScript.is_near_miss(ACHIEVE, 5, 5), "met is not a near miss")
	assert_false(GoalStatusScript.is_near_miss(AVOID, 4, 5), "avoid goals never pulse")


func test_progress_ratio_survives_a_zero_target() -> void:
	assert_eq(GoalStatusScript.progress_ratio(3, 0), 3.0)
