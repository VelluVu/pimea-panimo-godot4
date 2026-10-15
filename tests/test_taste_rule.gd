@tool
extends McpTestSuite


func suite_name() -> String:
	return "taste_rule"


func _batch(style : BeerStyle.Style, abv : float = 5.0, ebc : int = 10, quality : float = 1.0) -> BrewBatch:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	var batch := BrewBatch.new()
	batch.beer_style = beer_style
	batch.abv = abv
	batch.final_ebc = ebc
	batch.current_quality = quality
	return batch


func test_an_empty_rule_takes_anything() -> void:
	assert_true(TasteRule.new().matches(_batch(BeerStyle.Style.IPA)))


func test_styles_limit_the_rule() -> void:
	var rule := TasteRule.new()
	rule.styles = [BeerStyle.Style.HELLES, BeerStyle.Style.MARZEN]
	assert_true(rule.matches(_batch(BeerStyle.Style.MARZEN)))
	assert_false(rule.matches(_batch(BeerStyle.Style.IPA)))


func test_abv_must_be_above_the_limit() -> void:
	var rule := TasteRule.new()
	rule.min_abv_over = 7.0
	assert_false(rule.matches(_batch(BeerStyle.Style.SAHTI, 7.0)), "exactly 7 % is not over 7")
	assert_true(rule.matches(_batch(BeerStyle.Style.SAHTI, 7.1)))


func test_ebc_must_reach_the_limit() -> void:
	var rule := TasteRule.new()
	rule.min_ebc = 30
	assert_true(rule.matches(_batch(BeerStyle.Style.TUMMA_LAGER, 4.5, 30)))
	assert_false(rule.matches(_batch(BeerStyle.Style.TUMMA_LAGER, 4.5, 29)))


func test_spices_hops_and_malts_come_from_the_batch() -> void:
	var batch := _batch(BeerStyle.Style.SAISON)
	var spiced := TasteRule.new()
	spiced.needs_spices = true
	var fruity := TasteRule.new()
	fruity.late_hop_profiles = [HopData.FlavorProfile.CITRUS, HopData.FlavorProfile.TROPICAL]
	var malty := TasteRule.new()
	malty.malt_ids = [104, 106]
	assert_false(spiced.matches(batch))
	assert_false(fruity.matches(batch))
	assert_false(malty.matches(batch))
	batch.spiced = true
	batch.late_hop_profiles = [HopData.FlavorProfile.TROPICAL]
	batch.malt_ids = [100, 106]
	assert_true(spiced.matches(batch))
	assert_true(fruity.matches(batch))
	assert_true(malty.matches(batch))


func test_min_quality_drops_weaker_batches() -> void:
	var rule := TasteRule.new()
	rule.min_quality = 1.1
	assert_false(rule.matches(_batch(BeerStyle.Style.IPA, 5.0, 10, 1.05)))
	assert_true(rule.matches(_batch(BeerStyle.Style.IPA, 5.0, 10, 1.1)))


func test_any_matches_is_an_or() -> void:
	var helles := TasteRule.new()
	helles.styles = [BeerStyle.Style.HELLES]
	var strong := TasteRule.new()
	strong.min_abv_over = 7.0
	var rules : Array[TasteRule] = [helles, strong]
	assert_true(TasteRule.any_matches(rules, _batch(BeerStyle.Style.HELLES)))
	assert_true(TasteRule.any_matches(rules, _batch(BeerStyle.Style.DOPPELBOCK, 8.0)))
	assert_false(TasteRule.any_matches(rules, _batch(BeerStyle.Style.IPA)))
