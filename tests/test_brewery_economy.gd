@tool
extends McpTestSuite

## Unit tests for BatchDistributor.calculate_ship_payout(), the pure payout
## math behind the warehouse's ship-to-bar action, deliberately split out as static functions (see their own
## docstrings) so they're testable here without constructing a Brewery,
## which needs live autoloads in its own _init() — same limitation
## documented in test_brewery_xp_curve.gd and test_brew_resolver.gd.


func suite_name() -> String:
	return "brewery_economy"


func test_ship_payout_applies_bar_price_multiplier() -> void:
	var payout := BatchDistributor.calculate_ship_payout(2.0, 1.0, 10, 0.8)
	assert_true(is_equal_approx(payout, 16.0), "2.0 raw cost * 0.8 multiplier * 1.0 quality * 10 bottles = 16.0")


func test_ship_payout_clamps_quality_floor() -> void:
	# SHIP_TO_BAR_QUALITY_CLAMP_MIN is 0.3 — a spoiled batch (quality well
	# under that) should still pay the floor rate, not scale all the way to
	# zero.
	var spoiled := BatchDistributor.calculate_ship_payout(2.0, 0.05, 10, 0.8)
	var at_floor := BatchDistributor.calculate_ship_payout(2.0, BatchDistributor.SHIP_TO_BAR_QUALITY_CLAMP_MIN, 10, 0.8)
	assert_true(is_equal_approx(spoiled, at_floor), "quality below the clamp floor should pay exactly the floor rate")


func test_ship_payout_clamps_quality_ceiling() -> void:
	# SHIP_TO_BAR_QUALITY_CLAMP_MAX is 1.5 — a bar will pay a real premium
	# for excellence, but not an unbounded one.
	var masterful := BatchDistributor.calculate_ship_payout(2.0, 2.5, 10, 0.8)
	var at_ceiling := BatchDistributor.calculate_ship_payout(2.0, BatchDistributor.SHIP_TO_BAR_QUALITY_CLAMP_MAX, 10, 0.8)
	assert_true(is_equal_approx(masterful, at_ceiling), "quality above the clamp ceiling should pay exactly the ceiling rate")
