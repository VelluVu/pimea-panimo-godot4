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


func test_hop_stat_string_without_flavor_profile() -> void:
	var hop := HopData.new()
	hop.alpha_acids = 12
	hop.beta_acids = 4
	hop.flavor_profile = HopData.FlavorProfile.NONE
	assert_eq(hop.get_stat_string(), StringContainer.HOP_STAT_STRING % [12, 4])


func test_hop_stat_string_includes_flavor_profile_when_set() -> void:
	var hop := HopData.new()
	hop.alpha_acids = 12
	hop.beta_acids = 4
	hop.flavor_profile = HopData.FlavorProfile.CITRUS
	var expected := StringContainer.HOP_STAT_STRING % [12, 4] + "\n" + StringContainer.HOP_FLAVOR_STRING % HopData.get_flavor_profile_display_name(HopData.FlavorProfile.CITRUS)
	assert_eq(hop.get_stat_string(), expected)
