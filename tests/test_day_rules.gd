@tool
extends McpTestSuite

## Unit tests for DayRules, the pure day rules behind TimeManager: bills, the
## survival ending, day progress and the clock's restart time. Loaded by path so
## the suite always runs the script as it is on disk.

const DayRulesScript := preload("res://src/brewery/day_rules.gd")

const ENOUGH_REPUTATION : int = 100


func suite_name() -> String:
	return "day_rules"


func test_the_daily_bill_is_electricity_plus_water() -> void:
	assert_eq(DayRulesScript.daily_bill_total(), DayRulesScript.DAILY_ELECTRICITY_COST + DayRulesScript.DAILY_WATER_COST)
	assert_gt(DayRulesScript.daily_bill_total(), 0)


func test_survival_is_reached_on_the_target_day_with_enough_reputation_and_money() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_true(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 10.0, false, false))


func test_survival_needs_the_target_day() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET - 1
	assert_false(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 10.0, false, false))


func test_survival_holds_on_later_days_too() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET + 5
	assert_true(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 10.0, false, false))


func test_survival_needs_enough_reputation() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_false(DayRulesScript.survival_reached(day, Brewery.SURVIVAL_MIN_REPUTATION - 1, 10.0, false, false))
	assert_true(DayRulesScript.survival_reached(day, Brewery.SURVIVAL_MIN_REPUTATION, 10.0, false, false))


func test_survival_needs_money_above_zero() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_false(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 0.0, false, false))
	assert_false(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, -5.0, false, false))


func test_survival_never_fires_after_the_run_has_ended() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_false(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 10.0, true, false))


func test_survival_never_fires_again_once_the_player_chose_to_continue() -> void:
	var day : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_false(DayRulesScript.survival_reached(day, ENOUGH_REPUTATION, 10.0, false, true))


func test_day_progress_is_the_fraction_of_the_timer_spent() -> void:
	assert_eq(DayRulesScript.day_progress(true, 300.0, 300.0), 0.0)
	assert_eq(DayRulesScript.day_progress(true, 300.0, 150.0), 0.5)
	assert_eq(DayRulesScript.day_progress(true, 300.0, 0.0), 1.0)


func test_day_progress_is_zero_while_the_clock_is_stopped() -> void:
	assert_eq(DayRulesScript.day_progress(false, 300.0, 100.0), 0.0)


func test_day_progress_survives_a_zero_wait_time() -> void:
	assert_eq(DayRulesScript.day_progress(true, 0.0, 0.0), 0.0)


func test_the_clock_starts_a_full_day_when_nothing_was_saved() -> void:
	assert_eq(DayRulesScript.clock_start_seconds(-1.0, 300.0), 300.0)


func test_the_clock_resumes_from_the_saved_time_left() -> void:
	assert_eq(DayRulesScript.clock_start_seconds(120.0, 300.0), 120.0)


func test_a_saved_zero_resumes_at_zero_not_a_full_day() -> void:
	assert_eq(DayRulesScript.clock_start_seconds(0.0, 300.0), 0.0)
