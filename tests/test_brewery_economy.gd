@tool
extends McpTestSuite

## Unit tests for BatchDistributor.calculate_bulk_sell_payout()/calculate_ship_payout()
## — the pure payout math behind the warehouse's bulk-sell and ship-to-bar
## actions, deliberately split out as static functions (see their own
## docstrings) so they're testable here without constructing a Brewery,
## which needs live autoloads in its own _init() — same limitation
## documented in test_brewery_xp_curve.gd and test_brew_resolver.gd.


func suite_name() -> String:
	return "brewery_economy"


func test_bulk_sell_payout_at_full_quality_is_half_raw_cost() -> void:
	# BULK_SELL_RATE is 0.5 — quality 1.0 should never earn more than that,
	# the whole point of this action being worse than a real sale.
	var payout := BatchDistributor.calculate_bulk_sell_payout(2.0, 1.0, 10)
	assert_true(is_equal_approx(payout, 10.0), "2.0 raw cost * 0.5 rate * 1.0 quality * 10 bottles = 10.0")


func test_bulk_sell_payout_scales_down_with_quality() -> void:
	var poor := BatchDistributor.calculate_bulk_sell_payout(2.0, 0.2, 10)
	assert_true(is_equal_approx(poor, 2.0), "2.0 * 0.5 * 0.2 * 10 = 2.0 — well under raw cost")


func test_bulk_sell_payout_clamps_quality_at_one() -> void:
	# A masterful batch (quality > 1.0) must not out-earn a merely-good one —
	# see BULK_SELL_RATE's docstring: this is a fire-sale, not a premium.
	var excellent := BatchDistributor.calculate_bulk_sell_payout(2.0, 2.5, 10)
	var good := BatchDistributor.calculate_bulk_sell_payout(2.0, 1.0, 10)
	assert_true(is_equal_approx(excellent, good), "quality above 1.0 should clamp to the same payout as quality 1.0")


func test_bulk_sell_payout_zero_bottles_is_zero() -> void:
	assert_eq(BatchDistributor.calculate_bulk_sell_payout(2.0, 1.0, 0), 0.0)


func test_ship_payout_applies_bar_price_multiplier() -> void:
	var payout := BatchDistributor.calculate_ship_payout(2.0, 1.0, 10, 0.8)
	assert_true(is_equal_approx(payout, 16.0), "2.0 raw cost * 0.8 multiplier * 1.0 quality * 10 bottles = 16.0")


func test_ship_payout_clamps_quality_floor() -> void:
	# SHIP_TO_BAR_QUALITY_CLAMP_MIN is 0.3 — a spoiled batch (quality well
	# under that) should still pay the floor rate, not scale all the way to
	# zero the way bulk-sell can.
	var spoiled := BatchDistributor.calculate_ship_payout(2.0, 0.05, 10, 0.8)
	var at_floor := BatchDistributor.calculate_ship_payout(2.0, BatchDistributor.SHIP_TO_BAR_QUALITY_CLAMP_MIN, 10, 0.8)
	assert_true(is_equal_approx(spoiled, at_floor), "quality below the clamp floor should pay exactly the floor rate")


func test_ship_payout_clamps_quality_ceiling() -> void:
	# SHIP_TO_BAR_QUALITY_CLAMP_MAX is 1.3 — a bar will pay a real premium
	# for excellence, but not an unbounded one.
	var masterful := BatchDistributor.calculate_ship_payout(2.0, 2.5, 10, 0.8)
	var at_ceiling := BatchDistributor.calculate_ship_payout(2.0, BatchDistributor.SHIP_TO_BAR_QUALITY_CLAMP_MAX, 10, 0.8)
	assert_true(is_equal_approx(masterful, at_ceiling), "quality above the clamp ceiling should pay exactly the ceiling rate")


func test_ship_payout_beats_bulk_sell_at_the_same_quality() -> void:
	# The whole point of the two-tier design: shipping to even the cheapest
	# bar contact (price_multiplier 0.8) should out-earn dumping the same
	# batch via bulk-sell (fixed at BULK_SELL_RATE 0.5).
	var bulk := BatchDistributor.calculate_bulk_sell_payout(2.0, 1.0, 10)
	var shipped := BatchDistributor.calculate_ship_payout(2.0, 1.0, 10, 0.8)
	assert_true(shipped > bulk, "shipping should out-earn bulk-selling the same batch")
