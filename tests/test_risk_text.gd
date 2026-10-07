@tool
extends McpTestSuite

const RiskTextScript := preload("res://src/ui/risk_text.gd")


func suite_name() -> String:
	return "risk_text"


func test_the_label_shows_risk_against_the_runs_own_threshold() -> void:
	assert_eq(RiskTextScript.label(62, 85), "LVV-riski: 62/85")


func test_the_warning_follows_the_threshold() -> void:
	assert_false(RiskTextScript.is_warning(59, 85))
	assert_true(RiskTextScript.is_warning(60, 85))
	assert_false(RiskTextScript.is_warning(90, 130))
	assert_true(RiskTextScript.is_warning(105, 130))


func test_the_tooltip_explains_a_moved_threshold() -> void:
	var text : String = RiskTextScript.tooltip(62, 105, 100, 20, 15, 1, 3, 60.0, 24)
	assert_contains(text, "Riski 62, ratsiakynnys 105")
	assert_contains(text, "43 riskiä ennen ratsiaa")
	assert_contains(text, "Peruskynnys 100, perkit +20, maine -15")
	assert_contains(text, "Ratsiat: 1/3")
	assert_contains(text, "sakko 60.0 €, mainetta -24")


func test_an_untouched_threshold_skips_the_breakdown() -> void:
	var text : String = RiskTextScript.tooltip(10, 100, 100, 0, 0, 0, 3, 6.0, 2)
	assert_false(text.contains("Peruskynnys"))


func test_the_last_strike_warns_instead_of_pricing_the_raid() -> void:
	var text : String = RiskTextScript.tooltip(10, 100, 100, 0, 0, 2, 3, 60.0, 24)
	assert_contains(text, RiskTextScript.LAST_RAID_TEXT)
	assert_false(text.contains("sakko"))


func test_risk_past_the_threshold_shows_no_negative_margin() -> void:
	assert_contains(RiskTextScript.tooltip(120, 100, 100, 0, 0, 0, 3, 6.0, 2), "0 riskiä ennen ratsiaa")
