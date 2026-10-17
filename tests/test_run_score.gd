@tool
extends McpTestSuite

## Unit tests for RunScore: the leaderboard score, its parts and the renown it pays.

const RunScoreScript := preload("res://src/progression/run_score.gd")
const DayRulesScript := preload("res://src/brewery/day_rules.gd")


func suite_name() -> String:
	return "run_score"


func test_the_score_adds_days_reputation_and_bottles() -> void:
	assert_eq(RunScoreScript.score(10, 20, 30, DayRulesScript.ENDING_SEASON_OVER), 10 * 100 + 20 * 10 + 30 / 2)


func test_a_failed_run_scores_no_reputation() -> void:
	for ending : String in ["busted", "bankrupt"]:
		assert_eq(RunScoreScript.score(14, 475, 1491, ending), 14 * 100 + 1491 / 2)


func test_a_legend_beats_a_failed_run_with_huge_reputation() -> void:
	var legend : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SURVIVED)
	var busted : int = RunScoreScript.score(14, 475, 1491, "busted")
	assert_gt(legend, busted)


func test_rescore_matches_a_fresh_score() -> void:
	var entry : Dictionary = RunScoreScript.entry(14, 475, 1491, "busted")
	entry["score"] = 99999
	assert_eq(RunScoreScript.rescore(entry), RunScoreScript.score(14, 475, 1491, "busted"))


func test_days_count_only_up_to_the_season_end() -> void:
	var target : int = DayRulesScript.SURVIVAL_DAY_TARGET
	assert_eq(RunScoreScript.score(target + 10, 0, 0, "busted"), RunScoreScript.score(target, 0, 0, "busted"))


func test_only_a_legend_gets_the_survival_bonus() -> void:
	var legend : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SURVIVED)
	var season_over : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SEASON_OVER)
	assert_eq(legend - season_over, RunScoreScript.SURVIVAL_BONUS)


func test_a_legend_beats_a_strong_run_that_fell_short() -> void:
	var legend : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SURVIVED)
	var fell_short : int = RunScoreScript.score(15, 99, 900, DayRulesScript.ENDING_SEASON_OVER)
	assert_gt(legend, fell_short)


func test_negative_reputation_scores_zero_not_below() -> void:
	assert_eq(RunScoreScript.score(3, -20, 0, "busted"), 300)


func test_renown_is_the_score_scaled_down_with_a_floor() -> void:
	assert_eq(RunScoreScript.renown(4000), 200)
	assert_eq(RunScoreScript.renown(0), RunScoreScript.RENOWN_FLOOR)


func test_a_continued_night_pays_far_less_renown_than_a_scored_day() -> void:
	var continued : int = RunScoreScript.continued_day_renown(30)
	var scored_day : int = roundi((RunScoreScript.DAY_POINTS + 30) / RunScoreScript.RENOWN_DIVISOR)
	assert_gt(continued, 0)
	assert_gt(scored_day, continued)


func test_the_entry_holds_the_parts_of_its_score() -> void:
	var entry : Dictionary = RunScoreScript.entry(15, 110, 400, DayRulesScript.ENDING_SURVIVED)
	assert_eq(entry["days_survived"], 15)
	assert_eq(entry["bonus"], RunScoreScript.SURVIVAL_BONUS)
	assert_eq(entry["score"], 15 * 100 + 110 * 10 + 400 / 2 + RunScoreScript.SURVIVAL_BONUS)


func test_the_brewerys_worth_adds_points() -> void:
	var without : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SEASON_OVER)
	var with_worth : int = RunScoreScript.score(15, 100, 300, DayRulesScript.ENDING_SEASON_OVER, 1000.0)
	assert_eq(with_worth - without, roundi(1000.0 * RunScoreScript.WORTH_POINTS_PER_EURO))


func test_upgrades_are_worth_more_than_the_same_money() -> void:
	assert_eq(RunScoreScript.worth_of(1000.0, 0.0), 500.0, "cash counts at half")
	assert_eq(RunScoreScript.worth_of(0.0, 1000.0), 1000.0, "upgrades count at what they cost")
	assert_eq(RunScoreScript.worth_of(200.0, 300.0), 400.0)


func test_a_failed_run_scores_no_worth() -> void:
	assert_eq(RunScoreScript.worth_points(5000.0, "busted"), 0)
	assert_eq(RunScoreScript.worth_points(5000.0, "bankrupt"), 0)


func test_debt_is_not_negative_worth() -> void:
	assert_eq(RunScoreScript.worth_points(-200.0, DayRulesScript.ENDING_SURVIVED), 0)


func test_rescore_keeps_the_worth() -> void:
	var entry : Dictionary = RunScoreScript.entry(15, 120, 400, DayRulesScript.ENDING_SURVIVED, 2500.0)
	assert_eq(RunScoreScript.rescore(entry), entry["score"])


func test_every_style_brewed_this_season_adds_points() -> void:
	var plain : int = RunScoreScript.score(10, 20, 30, DayRulesScript.ENDING_SEASON_OVER)
	assert_eq(RunScoreScript.score(10, 20, 30, DayRulesScript.ENDING_SEASON_OVER, 0.0, 4), plain + 4 * RunScoreScript.STYLE_POINTS)


func test_styles_count_even_when_the_run_fails() -> void:
	assert_eq(RunScoreScript.score(5, 100, 0, "busted", 0.0, 3), 5 * 100 + 3 * RunScoreScript.STYLE_POINTS)


func test_rescore_keeps_the_styles() -> void:
	var entry : Dictionary = RunScoreScript.entry(15, 120, 400, DayRulesScript.ENDING_SEASON_OVER, 500.0, 9)
	assert_eq(entry.styles_brewed, 9)
	assert_eq(RunScoreScript.rescore(entry), entry.score)


func test_an_old_entry_without_styles_rescores_unchanged() -> void:
	var entry : Dictionary = RunScoreScript.entry(15, 120, 400, DayRulesScript.ENDING_SEASON_OVER, 500.0)
	entry.erase("styles_brewed")
	assert_eq(RunScoreScript.rescore(entry), entry.score)


func test_two_servings_make_a_point() -> void:
	assert_eq(RunScoreScript.bottle_points(0), 0)
	assert_eq(RunScoreScript.bottle_points(1), 0, "rounded down like the leaderboard SQL")
	assert_eq(RunScoreScript.bottle_points(401), 200)
