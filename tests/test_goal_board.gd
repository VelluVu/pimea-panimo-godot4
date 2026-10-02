@tool
extends McpTestSuite

## GoalBoard on its own, with its default hooks (always may roll, day 1, baseline
## 0, no rewards): progress, settling, refilling and restoring slots. DailyGoalData
## supplies the goal kinds. _ready() is never called.


func suite_name() -> String:
	return "goal_board"


func _goal(goal_type : DailyGoalData.GoalType, target : int = 3) -> DailyGoalData:
	var goal := DailyGoalData.new()
	goal.goal_name = DailyGoalData.GoalType.keys()[goal_type]
	goal.goal_type = goal_type
	goal.target_amount = target
	return goal


func _make_board(pool : Array[GoalData], slot_count : int = 1) -> GoalBoard:
	var board : GoalBoard = track(GoalBoard.new())
	board.set_slot_count(slot_count)
	board.goal_pool = pool
	return board


func _resolutions(board : GoalBoard) -> Array[Dictionary]:
	var log : Array[Dictionary] = []
	board.goal_resolved.connect(func(goal : GoalData, succeeded : bool) -> void:
		log.append({"name": goal.goal_name, "succeeded": succeeded}))
	return log


func test_fill_empty_slots_rolls_distinct_kinds() -> void:
	var board := _make_board([_goal(DailyGoalData.GoalType.SELL_BOTTLES), _goal(DailyGoalData.GoalType.EARN_MONEY)], 2)
	board.fill_empty_slots()
	var goals : Array[GoalData] = board.active_goals
	assert_true(goals[0] != null and goals[1] != null)
	assert_ne(goals[0].get_kind(), goals[1].get_kind())


func test_a_slot_stays_empty_when_the_pool_has_no_new_kind() -> void:
	var board := _make_board([_goal(DailyGoalData.GoalType.SELL_BOTTLES)], 2)
	board.fill_empty_slots()
	assert_eq(board.active_goals.count(null), 1)


func test_reaching_the_target_settles_the_goal_and_rolls_a_replacement() -> void:
	var sell := _goal(DailyGoalData.GoalType.SELL_BOTTLES, 3)
	var money := _goal(DailyGoalData.GoalType.EARN_MONEY)
	var board := _make_board([sell, money])
	board.load_slot(0, sell, 0, 0, 3)
	var log := _resolutions(board)

	board.add_progress(DailyGoalData.GoalType.SELL_BOTTLES, 2)
	assert_eq(log.size(), 0)
	board.add_progress(DailyGoalData.GoalType.SELL_BOTTLES, 1)

	assert_eq(log, [{"name": "SELL_BOTTLES", "succeeded": true}])
	assert_eq(board.active_goals[0], money, "the replacement is rolled while the settled goal still counts as active")
	assert_eq(board.get_progress(0), 0)


func test_progress_of_another_kind_is_ignored() -> void:
	var sell := _goal(DailyGoalData.GoalType.SELL_BOTTLES, 3)
	var board := _make_board([sell])
	board.load_slot(0, sell, 0, 0, 3)
	board.add_progress(DailyGoalData.GoalType.EARN_MONEY, 50)
	assert_eq(board.get_progress(0), 0)


func test_an_avoid_goal_fails_the_moment_it_passes_its_target() -> void:
	var unhappy := _goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 1)
	var board := _make_board([unhappy])
	board.load_slot(0, unhappy, 0, 0, 1)
	var log := _resolutions(board)
	board.add_progress(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 1)
	assert_eq(log.size(), 0, "reaching the limit is still allowed")
	board.add_progress(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 1)
	assert_eq(log, [{"name": "UNHAPPY_CUSTOMERS_MAX", "succeeded": false}])


func test_end_period_passes_avoid_goals_and_fails_unfinished_ones() -> void:
	var unhappy := _goal(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 2)
	var sell := _goal(DailyGoalData.GoalType.SELL_BOTTLES, 5)
	var board := _make_board([unhappy, sell], 2)
	board.load_slot(0, unhappy, 1, 0, 2)
	board.load_slot(1, sell, 4, 0, 5)
	var log := _resolutions(board)

	board.end_period()

	assert_eq(log, [{"name": "UNHAPPY_CUSTOMERS_MAX", "succeeded": true}, {"name": "SELL_BOTTLES", "succeeded": false}])


func test_fail_kind_without_penalty_settles_only_that_kind() -> void:
	var event := _goal(DailyGoalData.GoalType.SPECIAL_EVENT, 1)
	var sell := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var board := _make_board([event, sell], 2)
	board.load_slot(0, event, 0, 0, 1)
	board.load_slot(1, sell, 0, 0, 3)
	var log := _resolutions(board)

	board.fail_kind_without_penalty(DailyGoalData.GoalType.SPECIAL_EVENT)

	assert_eq(log, [{"name": "SPECIAL_EVENT", "succeeded": false}])
	assert_eq(board.active_goals[1], sell)


func test_set_progress_settles_a_goal_that_reaches_its_target() -> void:
	var rep := _goal(DailyGoalData.GoalType.REPUTATION_GAIN, 10)
	var board := _make_board([rep])
	board.load_slot(0, rep, 0, 40, 10)
	var log := _resolutions(board)
	board.set_progress(0, 10)
	assert_eq(log.size(), 1)


func test_set_progress_on_an_empty_slot_does_nothing() -> void:
	var board := _make_board([])
	board.set_progress(0, 5)
	assert_eq(board.get_progress(0), 0)


func test_load_slot_restores_every_field() -> void:
	var sell := _goal(DailyGoalData.GoalType.SELL_BOTTLES)
	var board := _make_board([sell])
	board.load_slot(0, sell, 2, 17, 9)
	assert_eq(board.active_goals[0], sell)
	assert_eq(board.get_progress(0), 2)
	assert_eq(board.get_baseline(0), 17)
	assert_eq(board.get_effective_target(0), 9)


func test_a_settled_goal_is_not_replaced_once_the_roll_limit_is_used() -> void:
	var board := _make_board([_goal(DailyGoalData.GoalType.SELL_BOTTLES, 1), _goal(DailyGoalData.GoalType.EARN_MONEY, 1)])
	board.roll_limit = 2
	board.fill_empty_slots()
	board.add_progress(board.active_goals[0].get_kind(), 1)
	assert_true(board.active_goals[0] != null, "the second roll fits the limit")
	board.add_progress(board.active_goals[0].get_kind(), 1)
	assert_eq(board.active_goals[0], null, "a third roll would pass the limit")
	assert_eq(board.get_rolls_left(), 0)


func test_end_period_starts_a_new_roll_budget() -> void:
	var board := _make_board([_goal(DailyGoalData.GoalType.SELL_BOTTLES, 1), _goal(DailyGoalData.GoalType.EARN_MONEY, 1)])
	board.roll_limit = 1
	board.fill_empty_slots()
	board.add_progress(board.active_goals[0].get_kind(), 1)
	assert_eq(board.active_goals[0], null)
	board.end_period()
	board.fill_empty_slots()
	assert_true(board.active_goals[0] != null, "a new period rolls again")
	assert_eq(board.rolls_used, 1)


func test_without_a_limit_rolls_left_is_minus_one() -> void:
	var board := _make_board([_goal(DailyGoalData.GoalType.SELL_BOTTLES)])
	board.fill_empty_slots()
	assert_eq(board.get_rolls_left(), -1)
