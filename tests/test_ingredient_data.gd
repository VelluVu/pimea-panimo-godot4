@tool
extends McpTestSuite

## Unit tests for IngredientData/MaltData/HopData/YeastData's pure
## color/unit lookups and stat-string formatting.


func suite_name() -> String:
	return "ingredient_data"


func test_get_color_for_type_matches_each_type() -> void:
	assert_eq(IngredientData.get_color_for_type(IngredientData.IngredientType.MALT), Color.WHEAT)
	assert_eq(IngredientData.get_color_for_type(IngredientData.IngredientType.HOP), Color.GREEN_YELLOW)
	assert_eq(IngredientData.get_color_for_type(IngredientData.IngredientType.YEAST), Color.DARK_GOLDENROD)


func test_get_unit_string_matches_each_type() -> void:
	var malt := MaltData.new()
	malt.type = IngredientData.IngredientType.MALT
	assert_eq(malt.get_unit_string(), StringContainer.KG)

	var hop := HopData.new()
	hop.type = IngredientData.IngredientType.HOP
	assert_eq(hop.get_unit_string(), StringContainer.G)

	var yeast := YeastData.new()
	yeast.type = IngredientData.IngredientType.YEAST
	assert_eq(yeast.get_unit_string(), StringContainer.KPL)


func test_malt_stat_string_includes_ebc() -> void:
	var malt := MaltData.new()
	malt.ebc = 42
	assert_eq(malt.get_stat_string(), StringContainer.MALT_STAT_STRING % 42)


func test_yeast_stat_string_includes_attenuation() -> void:
	var yeast := YeastData.new()
	yeast.attentuation_percent = 75
	assert_eq(yeast.get_stat_string(), StringContainer.YEAST_STAT_STRING % 75)


func test_bittering_hop_shows_its_use() -> void:
	var hop := HopData.new()
	hop.alpha_acids = 16
	hop.beta_acids = 4
	hop.flavor_profile = HopData.FlavorProfile.NONE
	var expected := StringContainer.HOP_STAT_STRING % [16, 4] + "
" + HopData.USE_FORMAT % HopData.USE_BITTERING
	assert_eq(hop.get_stat_string(), expected)


func test_aroma_hop_shows_use_and_flavor() -> void:
	var hop := HopData.new()
	hop.alpha_acids = 12
	hop.beta_acids = 4
	hop.flavor_profile = HopData.FlavorProfile.CITRUS
	var expected := StringContainer.HOP_STAT_STRING % [12, 4] + "
" + HopData.USE_FLAVOR_FORMAT % [HopData.USE_DUAL, HopData.get_flavor_profile_display_name(HopData.FlavorProfile.CITRUS)]
	assert_eq(hop.get_stat_string(), expected)


func test_hop_use_follows_aroma_and_alpha() -> void:
	assert_eq(HopData.use_of(16, HopData.FlavorProfile.NONE), HopData.Use.BITTERING, "no aroma only bitters")
	assert_eq(HopData.use_of(4, HopData.FlavorProfile.NONE), HopData.Use.BITTERING, "even a mild hop without aroma")
	assert_eq(HopData.use_of(HopData.DUAL_ALPHA_MIN - 1, HopData.FlavorProfile.EARTHY), HopData.Use.AROMA)
	assert_eq(HopData.use_of(4, HopData.FlavorProfile.NOBLE), HopData.Use.AROMA, "suppliers class Saaz as an aroma hop")
	assert_eq(HopData.use_of(HopData.DUAL_ALPHA_MIN, HopData.FlavorProfile.CITRUS), HopData.Use.DUAL)


func test_a_hops_short_line_is_alpha_and_use() -> void:
	var hop := HopData.new()
	hop.alpha_acids = 5
	hop.flavor_profile = HopData.FlavorProfile.NOBLE
	assert_eq(hop.get_short_stat_string(), HopData.SHORT_FORMAT % [5, HopData.SHORT_AROMA])
	hop.alpha_acids = 16
	hop.flavor_profile = HopData.FlavorProfile.NONE
	assert_eq(hop.get_short_stat_string(), HopData.SHORT_FORMAT % [16, HopData.SHORT_BITTERING])


func test_other_ingredients_keep_their_stat_line_short() -> void:
	var malt := MaltData.new()
	malt.ebc = 3
	assert_eq(malt.get_short_stat_string(), malt.get_stat_string())
