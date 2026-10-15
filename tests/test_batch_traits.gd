@tool
extends McpTestSuite

const MAGNUM_ID : int = 200
const CASCADE_ID : int = 201
const CITRA_ID : int = 202
const CORIANDER_ID : int = 401
const PILSNER_ID : int = 100
const MUNICH_ID : int = 104


func suite_name() -> String:
	return "batch_traits"


func _hop(id : int, alpha : int, profile : HopData.FlavorProfile) -> HopData:
	var hop := HopData.new()
	hop.id = id
	hop.type = IngredientData.IngredientType.HOP
	hop.alpha_acids = alpha
	hop.flavor_profile = profile
	return hop


func _ingredient(id : int, type : IngredientData.IngredientType) -> IngredientData:
	var data := MaltData.new() if type == IngredientData.IngredientType.MALT else IngredientData.new()
	data.id = id
	data.type = type
	return data


func _table() -> Dictionary:
	return {
		MAGNUM_ID: _hop(MAGNUM_ID, 16, HopData.FlavorProfile.NONE),
		CASCADE_ID: _hop(CASCADE_ID, 6, HopData.FlavorProfile.CITRUS),
		CITRA_ID: _hop(CITRA_ID, 12, HopData.FlavorProfile.TROPICAL),
		CORIANDER_ID: _ingredient(CORIANDER_ID, IngredientData.IngredientType.SPICE),
		PILSNER_ID: _ingredient(PILSNER_ID, IngredientData.IngredientType.MALT),
		MUNICH_ID: _ingredient(MUNICH_ID, IngredientData.IngredientType.MALT),
	}


func _style(kinds : Array[HopAddition.Kind]) -> BeerStyle:
	var style := BeerStyle.new()
	style.hop_additions = kinds
	return style


func test_only_a_spice_the_style_likes_or_needs_counts() -> void:
	var style := BeerStyle.new()
	style.preferred_spice_ids = [CORIANDER_ID]
	assert_true(BatchTraits.has_suitable_spice(style, {PILSNER_ID: 4, CORIANDER_ID: 10}))
	assert_false(BatchTraits.has_suitable_spice(style, {PILSNER_ID: 4, CORIANDER_ID: 0}))
	assert_false(BatchTraits.has_suitable_spice(style, {PILSNER_ID: 4, 406: 5}), "coffee does not suit it")
	var needs := BeerStyle.new()
	needs.required_spice_ids = [CORIANDER_ID]
	assert_true(BatchTraits.has_suitable_spice(needs, {CORIANDER_ID: 10}))


func test_malt_ids_lists_only_malts_sorted() -> void:
	var ids : Array[int] = BatchTraits.malt_ids({MUNICH_ID: 1, CASCADE_ID: 20, PILSNER_ID: 4}, _table())
	assert_eq(ids, [PILSNER_ID, MUNICH_ID] as Array[int])


func test_late_hops_come_from_aroma_and_dry_hop_marks() -> void:
	var style := _style([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA, HopAddition.Kind.DRY_HOP])
	var profiles : Array[HopData.FlavorProfile] = BatchTraits.late_hop_profiles(style, {MAGNUM_ID: 20, CASCADE_ID: 20, CITRA_ID: 20}, _table())
	assert_true(profiles.has(HopData.FlavorProfile.CITRUS), "Cascade goes in late")
	assert_true(profiles.has(HopData.FlavorProfile.TROPICAL), "Citra goes in late")


func test_a_bittering_only_style_has_no_late_hops() -> void:
	var style := _style([HopAddition.Kind.BITTERING])
	assert_true(BatchTraits.late_hop_profiles(style, {MAGNUM_ID: 20}, _table()).is_empty())


func test_a_hop_without_aroma_adds_no_late_flavour() -> void:
	var style := _style([HopAddition.Kind.AROMA])
	assert_true(BatchTraits.late_hop_profiles(style, {MAGNUM_ID: 20}, _table()).is_empty())


func test_apply_fills_the_batch() -> void:
	var batch := BrewBatch.new()
	batch.beer_style = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA])
	batch.beer_style.preferred_spice_ids = [CORIANDER_ID]
	BatchTraits.apply(batch, {PILSNER_ID: 4, MAGNUM_ID: 20, CASCADE_ID: 20, CORIANDER_ID: 5}, _table())
	assert_true(batch.spiced)
	assert_eq(batch.malt_ids, [PILSNER_ID] as Array[int])
	assert_eq(batch.late_hop_profiles, [HopData.FlavorProfile.CITRUS] as Array[HopData.FlavorProfile])


func test_hop_profiles_include_bittering_hops_with_a_flavour() -> void:
	var profiles : Array[HopData.FlavorProfile] = BatchTraits.hop_profiles({MAGNUM_ID: 20, CASCADE_ID: 5, PILSNER_ID: 4}, _table())
	assert_eq(profiles, [HopData.FlavorProfile.CITRUS] as Array[HopData.FlavorProfile], "Magnum has no flavour")
