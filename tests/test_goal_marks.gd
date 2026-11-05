@tool
extends McpTestSuite

const GoalMarksScript := preload("res://src/ui/goal_marks.gd")


func suite_name() -> String:
	return "goal_marks"


func test_a_met_goal_is_ticked_and_struck() -> void:
	assert_eq(GoalMarksScript.prefix_for(GoalStatus.State.MET), "✔ ")
	assert_true(GoalMarksScript.is_struck(GoalStatus.State.MET))


func test_a_failing_goal_is_crossed_but_not_struck() -> void:
	assert_eq(GoalMarksScript.prefix_for(GoalStatus.State.FAILING), "✖ ")
	assert_false(GoalMarksScript.is_struck(GoalStatus.State.FAILING))


func test_open_and_close_goals_have_no_mark() -> void:
	assert_eq(GoalMarksScript.prefix_for(GoalStatus.State.PENDING), "")
	assert_eq(GoalMarksScript.prefix_for(GoalStatus.State.WARNING), "")


func test_the_strike_skips_the_mark_on_a_right_aligned_line() -> void:
	# 160 px label, 100 px text with a 12 px mark: text starts at 60, the strike at 72.
	assert_eq(GoalMarksScript.strike_span(160.0, 100.0, 12.0), Vector2(72, 160))


func test_a_wrapped_line_is_not_struck() -> void:
	assert_eq(GoalMarksScript.strike_span(160.0, 200.0, 12.0), Vector2.ZERO)
