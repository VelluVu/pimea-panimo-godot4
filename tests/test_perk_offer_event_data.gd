@tool
extends McpTestSuite

## Paid offers (Keke's course, the renovator): the perk roll, the caller and the payment rules.


func suite_name() -> String:
	return "perk_offer_event_data"


func _make_offer(perk_count : int) -> PerkOfferEventData:
	var offer := PerkOfferEventData.new()
	offer.perk_count = perk_count
	for perk_name : String in ["A", "B", "C"]:
		var perk := RunPerk.new()
		perk.perk_name = perk_name
		offer.offered_perks.append(perk)
	return offer


func test_each_visit_rolls_different_perks() -> void:
	var offer := _make_offer(2)
	var rolled := offer.prepared(null, []) as PerkOfferEventData
	assert_true(rolled != offer, "a rolled copy, the shared resource stays clean")
	assert_eq(rolled.rolled_perks.size(), 2)
	assert_true(rolled.rolled_perks[0] != rolled.rolled_perks[1], "two different perks")
	assert_eq(rolled.perks_on_success(null), rolled.rolled_perks)


func test_a_count_above_the_pool_gives_the_whole_pool() -> void:
	assert_eq(PerkOfferEventData.pick_perks(_make_offer(1).offered_perks, 5).size(), 3)


func test_the_caller_is_one_of_the_names() -> void:
	var offer := _make_offer(1)
	offer.caller_names = ["Mirkku", "Pasi"]
	assert_true((offer.prepared(null, []) as PerkOfferEventData).event_caller_name in offer.caller_names)


func test_an_offer_takes_money_and_no_beer() -> void:
	var offer := _make_offer(1)
	assert_false(offer.waits_for_delivery())
	assert_eq(offer.servings_taken(null), {})
