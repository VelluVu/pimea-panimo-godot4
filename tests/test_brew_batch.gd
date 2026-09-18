@tool
extends McpTestSuite

## Unit tests for BrewBatch's aging math (age_one_day() / private
## _calculate_current_quality()) and the pure presentational helpers built
## on top of it. BrewBatch is a plain Resource with no autoload
## dependency, unlike most of Brewery's other systems (see
## test_brew_resolver.gd's class-level note) — so this is directly
## testable, but until now had no automated coverage at all: the aging
## rescale (rising -> plateau -> decline) was only ever confirmed by hand,
## via a 46-tick game_eval loop against a live game (see
## playtest_notes_7.txt). test_matches_confirmed_playtest_spoilage_case()
## below reproduces that exact scenario as a real regression test.


func suite_name() -> String:
	return "brew_batch"


func _make_batch(peak_days: int, shelf_life_days: int, aging_factor: float, original_quality: float = 1.0) -> BrewBatch:
	var style := BeerStyle.new()
	style.peak_days = peak_days
	style.shelf_life_days = shelf_life_days
	style.aging_factor = aging_factor

	var batch := BrewBatch.new()
	batch.beer_style = style
	batch.original_quality = original_quality
	batch.current_quality = original_quality
	return batch


func test_flat_style_with_no_peak_days_stays_at_original_quality() -> void:
	# Mirrors Kotikalja (peak_days 0): neither the rising branch (0 <= 0 only
	# holds at age 0) nor the decline branch (days_past_peak > shelf_life_days)
	# fires while still inside shelf_life_days, so current_quality is simply
	# never touched and stays at its original value.
	var batch := _make_batch(0, 40, 0.01)
	batch.age_one_day()
	assert_eq(batch.current_quality, 1.0)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_PLATEAU)


func test_matches_confirmed_playtest_spoilage_case() -> void:
	# Exact numbers from playtest_notes_7.txt's live game_eval run: a fresh
	# Kotikalja batch (peak_days 0, shelf_life_days 40, aging_factor 0.01)
	# aged 46 ticks landed on 0.88 (1.0 - 0.02*6, 6 ticks past the 40-tick
	# shelf life) and flipped the trend icon to declining.
	var batch := _make_batch(0, 40, 0.01)
	for i in range(46):
		batch.age_one_day()
	assert_eq(batch.current_quality, 0.88)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_DECLINING)


func test_rising_phase_interpolates_toward_peak_bonus() -> void:
	var batch := _make_batch(10, 5, 0.5)
	for i in range(5):
		batch.age_one_day()
	# progress = 5/10 = 0.5 -> original(1.0) + aging_factor(0.5) * 0.5
	assert_eq(batch.current_quality, 1.25)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_RISING)


func test_reaches_full_peak_bonus_exactly_at_peak_days() -> void:
	var batch := _make_batch(10, 5, 0.5)
	for i in range(10):
		batch.age_one_day()
	assert_eq(batch.current_quality, 1.5)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_PLATEAU)


func test_plateau_holds_the_peak_value_through_shelf_life() -> void:
	var batch := _make_batch(10, 5, 0.5)
	for i in range(15):
		batch.age_one_day()
	assert_eq(batch.current_quality, 1.5)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_PLATEAU)


func test_decline_with_non_negative_aging_factor_resets_baseline_to_original_quality() -> void:
	# Characterizes real (if slightly surprising) existing behavior: once
	# decline starts, a non-negative aging_factor's flat 0.02/day decay is
	# computed from original_quality, not from the plateau value the batch
	# was just holding at — so quality visibly drops the moment decline
	# begins instead of continuing down from the peak. Not something this
	# pass is trying to fix, just locking in so a future change to this
	# formula is a deliberate decision, not an accidental one.
	var batch := _make_batch(10, 5, 0.5)
	for i in range(16):
		batch.age_one_day()
	# days_past_peak=6, spoilage_days=1 -> original(1.0) - 0.02*1 = 0.98,
	# not 1.5 - 0.02.
	assert_eq(batch.current_quality, 0.98)
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_DECLINING)


func test_decline_with_negative_aging_factor_uses_aging_factor_directly() -> void:
	var batch := _make_batch(5, 3, -0.1)
	for i in range(11):
		batch.age_one_day()
	# days_past_peak=6, spoilage_days=3 -> original(1.0) + (-0.1)*3 = 0.7
	assert_true(is_equal_approx(batch.current_quality, 0.7), "expected ~0.7, got %s" % batch.current_quality)


func test_current_quality_is_clamped_to_floor() -> void:
	var batch := _make_batch(0, 0, -1.0)
	for i in range(50):
		batch.age_one_day()
	assert_eq(batch.current_quality, 0.1)


## MetaUnlockData's brewing capstone (Panimomestari) grants exactly this:
## a batch reaching peak sooner because peak_days is scaled down before
## the rising-phase math ever runs.
func test_peak_days_multiplier_speeds_up_reaching_peak() -> void:
	var batch := _make_batch(10, 5, 0.5)
	batch.peak_days_multiplier = 0.5 # effective peak_days = 5, not 10
	for i in range(5):
		batch.age_one_day()
	assert_eq(batch.current_quality, 1.5, "5 days in should already be at full peak bonus with peak_days halved")
	assert_eq(batch.get_aging_trend_icon(), BrewBatch.AGING_TREND_PLATEAU)


func test_decline_rate_multiplier_slows_post_shelf_life_quality_loss() -> void:
	var with_multiplier := _make_batch(10, 5, 0.5)
	with_multiplier.decline_rate_multiplier = 0.5
	var without_multiplier := _make_batch(10, 5, 0.5)

	for i in range(16):
		with_multiplier.age_one_day()
		without_multiplier.age_one_day()

	# days_past_peak=6, spoilage_days=1 -> without: original(1.0) - 0.02*1 = 0.98;
	# with a 0.5 decline_rate_multiplier: original(1.0) - 0.02*1*0.5 = 0.99.
	assert_eq(without_multiplier.current_quality, 0.98)
	assert_eq(with_multiplier.current_quality, 0.99)
	assert_true(with_multiplier.current_quality > without_multiplier.current_quality, "a slower decline rate should lose less quality over the same aging")


func test_quality_tier_boundaries() -> void:
	var batch := _make_batch(0, 100, 0.0)
	batch.current_quality = 0.69
	assert_eq(batch.get_quality_tier_string(), StringContainer.QUALITY_TIER_POOR)
	batch.current_quality = 0.7
	assert_eq(batch.get_quality_tier_string(), StringContainer.QUALITY_TIER_MEDIOCRE)
	batch.current_quality = 0.9
	assert_eq(batch.get_quality_tier_string(), StringContainer.QUALITY_TIER_GOOD)
	batch.current_quality = 1.1
	assert_eq(batch.get_quality_tier_string(), StringContainer.QUALITY_TIER_EXCELLENT)
	batch.current_quality = 1.3
	assert_eq(batch.get_quality_tier_string(), StringContainer.QUALITY_TIER_MASTERFUL)
