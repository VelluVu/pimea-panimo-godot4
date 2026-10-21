@tool
extends McpTestSuite

## Unit tests for RiskPressure: the LVV risk's share of the raid threshold, eased.

const RiskPressureScript := preload("res://src/ui/risk_pressure.gd")


func suite_name() -> String:
	return "risk_pressure"


func test_calm_below_the_start_share() -> void:
	assert_eq(RiskPressureScript.of(0, 100), 0.0)
	assert_eq(RiskPressureScript.of(45, 100), 0.0)


func test_full_at_and_over_the_threshold() -> void:
	assert_eq(RiskPressureScript.of(100, 100), 1.0)
	assert_eq(RiskPressureScript.of(140, 100), 1.0)


func test_grows_between_start_and_threshold() -> void:
	var low : float = RiskPressureScript.of(60, 100)
	var high : float = RiskPressureScript.of(90, 100)
	assert_true(low > 0.0 and low < high and high < 1.0, "%f %f" % [low, high])


func test_follows_the_runs_own_threshold() -> void:
	assert_eq(RiskPressureScript.of(90, 200), 0.0)
	assert_eq(RiskPressureScript.of(200, 200), 1.0)


func test_no_threshold_means_no_pressure() -> void:
	assert_eq(RiskPressureScript.of(50, 0), 0.0)
