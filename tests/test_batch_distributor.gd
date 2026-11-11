@tool
extends McpTestSuite

## Unit tests for BatchDistributor's payout for a keg shipped to a bar.

const BatchDistributorScript := preload("res://src/brewery/batch_distributor.gd")


func suite_name() -> String:
	return "batch_distributor"


func _payout_is(wholesale : float, quality : float, bottles : int, multiplier : float, expected : float) -> void:
	assert_true(is_equal_approx(BatchDistributorScript.calculate_ship_payout(wholesale, quality, bottles, multiplier), expected))


func test_the_payout_multiplies_price_quality_bottles_and_the_bar() -> void:
	_payout_is(2.0, 1.0, 10, 1.0, 20.0)
	_payout_is(2.0, 1.0, 10, 1.5, 30.0)


func test_bad_beer_is_still_paid_the_minimum_quality() -> void:
	_payout_is(2.0, 0.1, 10, 1.0, 2.0 * BatchDistributorScript.SHIP_TO_BAR_QUALITY_CLAMP_MIN * 10.0)


func test_quality_past_the_cap_earns_no_more() -> void:
	_payout_is(2.0, 5.0, 10, 1.0, 2.0 * BatchDistributorScript.SHIP_TO_BAR_QUALITY_CLAMP_MAX * 10.0)


func test_no_bottles_pay_nothing() -> void:
	_payout_is(2.0, 1.0, 0, 1.0, 0.0)
