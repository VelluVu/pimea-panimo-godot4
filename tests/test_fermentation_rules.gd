@tool
extends McpTestSuite

## Unit tests for FermentationRules, the fermenting part of Inventory and BrewBatch.sour().

const FermentationRulesScript := preload("res://src/brewing/fermentation_rules.gd")


func suite_name() -> String:
	return "fermentation_rules"


func _make_batch(quality : float = 1.0) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.beer_style = BeerStyle.new()
	batch.original_quality = quality
	batch.current_quality = quality
	return batch


func assert_near(actual : float, expected : float, tolerance : float) -> void:
	assert_true(absf(actual - expected) <= tolerance, "%s is not near %s" % [actual, expected])


func test_the_first_brew_skips_fermentation() -> void:
	assert_eq(FermentationRulesScript.duration(true), 0.0)
	assert_eq(FermentationRulesScript.duration(false), FermentationRulesScript.SECONDS)


func test_a_clean_keg_never_sours() -> void:
	assert_eq(FermentationRulesScript.infection_chance(KegRules.CLEAN, 0.0), 0.0)


func test_an_unwashed_keg_has_the_full_chance() -> void:
	assert_near(FermentationRulesScript.infection_chance(KegRules.DIRTY, 0.0), FermentationRulesScript.MAX_INFECTION_CHANCE, 0.0001)


func test_the_chance_grows_with_the_dirt() -> void:
	var half_washed : float = FermentationRulesScript.infection_chance(0.5, 0.0)
	assert_near(half_washed, FermentationRulesScript.MAX_INFECTION_CHANCE * 0.5, 0.0001)
	assert_true(FermentationRulesScript.infection_chance(0.2, 0.0) > half_washed)


func test_cleaning_perks_cut_the_chance() -> void:
	var base : float = FermentationRulesScript.infection_chance(KegRules.DIRTY, 0.0)
	assert_near(FermentationRulesScript.infection_chance(KegRules.DIRTY, 0.3), base * 0.7, 0.0001)
	assert_eq(FermentationRulesScript.infection_chance(KegRules.DIRTY, 1.5), 0.0)


func test_time_counts_down_to_zero_and_no_further() -> void:
	assert_eq(FermentationRulesScript.remaining(10.0, 4.0), 6.0)
	assert_eq(FermentationRulesScript.remaining(1.0, 4.0), 0.0)
	assert_true(FermentationRulesScript.is_done(0.0))
	assert_false(FermentationRulesScript.is_done(0.5))


func test_progress_runs_from_zero_to_one() -> void:
	assert_eq(FermentationRulesScript.progress(FermentationRulesScript.SECONDS), 0.0)
	assert_eq(FermentationRulesScript.progress(0.0), 1.0)


func test_a_fermenting_brew_reserves_a_keg() -> void:
	var inventory := Inventory.new()
	inventory.free_kegs = [KegRules.CLEAN] as Array[float]
	assert_true(inventory.has_free_keg())
	inventory.start_fermenting(_make_batch())
	assert_false(inventory.has_free_keg())
	assert_eq(inventory.kegs_in_use(), 1)
	assert_eq(inventory.total_kegs(), 1)


func test_a_fermented_batch_takes_the_cleanest_keg() -> void:
	var inventory := Inventory.new()
	inventory.free_kegs = [0.2, 0.9, 0.5] as Array[float]
	var batch := _make_batch()
	inventory.start_fermenting(batch)
	inventory.finish_fermenting(batch)
	assert_true(inventory.fermenting.is_empty())
	assert_true(inventory.brew_batches.has(batch))
	assert_eq(batch.keg_cleanliness, 0.9)
	assert_eq(inventory.free_kegs.size(), 2)


func test_a_soured_batch_loses_its_share_of_quality() -> void:
	var batch := _make_batch(1.2)
	batch.sour(0.25)
	assert_true(batch.infected)
	assert_near(batch.original_quality, 0.9, 0.01)
	assert_near(batch.current_quality, batch.original_quality, 0.01)
	assert_eq(batch.get_sour_level(), FermentationRulesScript.SourLevel.CLEAR)


func test_a_dirtier_keg_sours_worse() -> void:
	assert_near(FermentationRulesScript.sour_loss(KegRules.DIRTY, 1.0), FermentationRulesScript.MAX_SOUR_LOSS, 0.0001)
	assert_near(FermentationRulesScript.sour_loss(KegRules.DIRTY, 0.0), FermentationRulesScript.MAX_SOUR_LOSS * FermentationRulesScript.MIN_SOUR_ROLL, 0.0001)
	assert_near(FermentationRulesScript.sour_loss(0.5, 1.0), FermentationRulesScript.MAX_SOUR_LOSS * 0.5, 0.0001)
	assert_eq(FermentationRulesScript.sour_loss(KegRules.CLEAN, 1.0), 0.0)


func test_the_loss_sets_the_sour_level() -> void:
	assert_eq(FermentationRulesScript.sour_level(0.05), FermentationRulesScript.SourLevel.LIGHT)
	assert_eq(FermentationRulesScript.sour_level(0.15), FermentationRulesScript.SourLevel.CLEAR)
	assert_eq(FermentationRulesScript.sour_level(0.25), FermentationRulesScript.SourLevel.CLEAR)
	assert_eq(FermentationRulesScript.sour_level(0.3), FermentationRulesScript.SourLevel.STRONG)


func test_an_old_soured_batch_counts_as_clearly_sour() -> void:
	var batch := _make_batch()
	batch.infected = true
	assert_eq(batch.get_sour_level(), FermentationRulesScript.SourLevel.CLEAR)
	assert_eq(_make_batch().get_sour_level(), FermentationRulesScript.SourLevel.NONE)
