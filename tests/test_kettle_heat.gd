@tool
extends McpTestSuite

const KettleHeatScript := preload("res://src/brewing/brew_day/kettle_heat.gd")


func suite_name() -> String:
	return "kettle_heat"


func test_the_kettle_cools_without_heat() -> void:
	var heat = KettleHeatScript.new(60.0, 4.0, 0.5, 0.3)
	heat.step(2.0)
	assert_eq(heat.temperature, 59.0)


func test_the_burner_lags_behind_the_button() -> void:
	var heat = KettleHeatScript.new(60.0, 4.0, 0.0, 0.4)
	heat.heating = true
	heat.step(0.1)
	assert_true(heat.power > 0.0 and heat.power < 1.0)
	heat.heating = false
	var before : float = heat.temperature
	heat.step(0.1)
	assert_true(heat.temperature > before, "heat keeps coming after letting go")


func test_no_lag_follows_at_once() -> void:
	var heat = KettleHeatScript.new(60.0, 4.0, 0.0, 0.0)
	heat.heating = true
	heat.step(1.0)
	assert_eq(heat.temperature, 64.0)


func test_the_temperature_has_a_floor() -> void:
	var heat = KettleHeatScript.new(16.0, 4.0, 10.0, 0.3)
	heat.step(5.0)
	assert_eq(heat.temperature, KettleHeatScript.MIN_TEMPERATURE)
