@tool
extends McpTestSuite

## What a shipment to a bar does to LVV risk.


func suite_name() -> String:
	return "bar_contact"


func _make_style(abv : float) -> BeerStyle:
	var style := BeerStyle.new()
	style.abv = abv
	return style


func test_beer_adds_the_bars_risk() -> void:
	var bar := BarContact.new()
	bar.risk_per_shipment = 14
	assert_eq(bar.risk_for(_make_style(5.0)), 14)


func test_alcohol_free_keg_lowers_risk_anywhere() -> void:
	var bar := BarContact.new()
	bar.risk_per_shipment = 14
	assert_eq(bar.risk_for(_make_style(0.3)), BarContact.ALCOHOL_FREE_SHIPMENT_RISK)
	assert_true(BarContact.ALCOHOL_FREE_SHIPMENT_RISK < 0)


func test_alcohol_free_limit_is_inclusive() -> void:
	assert_true(_make_style(BeerStyle.ALCOHOL_FREE_MAX_ABV).is_alcohol_free())
	assert_false(_make_style(2.8).is_alcohol_free(), "kotikalja is not alcohol-free")
