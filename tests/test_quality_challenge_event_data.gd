@tool
extends McpTestSuite

## How strong the critic's perk is for a batch's quality.


func suite_name() -> String:
	return "quality_challenge_event_data"


func test_perk_is_weakest_at_the_quality_bar() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(1.2, 1.2, 1.6, 0.25), 0.25))


func test_perk_grows_with_quality() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(1.4, 1.2, 1.6, 0.25), 0.625))


func test_perk_never_passes_full_strength() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(2.2, 1.2, 1.6, 0.25), 1.0))


func test_higher_quality_wins_over_more_money() -> void:
	assert_true(QualityChallengeEventData.is_better(1.5, 10.0, 1.4, 200.0))


func test_equal_quality_goes_to_the_batch_worth_more() -> void:
	assert_true(QualityChallengeEventData.is_better(1.4, 150.0, 1.4, 100.0))
	assert_false(QualityChallengeEventData.is_better(1.4, 50.0, 1.4, 100.0))


func test_held_batch_is_not_on_offer() -> void:
	var event := QualityChallengeEventData.new()
	event.required_min_quality = 1.2
	event.required_bottles = 3
	var held := BrewBatch.new()
	held.beer_style = BeerStyle.new()
	held.amount_bottles = 40
	held.current_quality = 1.5
	held.held = true
	var inventory := Inventory.new()
	inventory.brew_batches.append(held)
	assert_eq(event.delivery_progress(inventory), Vector2i(0, 3))
