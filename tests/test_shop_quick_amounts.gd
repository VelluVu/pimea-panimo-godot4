@tool
extends McpTestSuite

## Unit tests for ShopQuickAmounts: quick buttons and purchase caps by how a thing is sold.

const QuickScript := preload("res://src/ui/shop_quick_amounts.gd")


func suite_name() -> String:
	return "shop_quick_amounts"


func test_hops_step_in_grams_and_allow_bigger_buys() -> void:
	var hop := HopData.new()
	hop.type = IngredientData.IngredientType.HOP
	assert_eq(QuickScript.steps(hop), [10, 25, 100] as Array[int])
	assert_eq(QuickScript.max_units(hop), QuickScript.MAX_GRAMS)


func test_malts_step_by_their_own_unit() -> void:
	var kilo := MaltData.new()
	kilo.type = IngredientData.IngredientType.MALT
	var pack := MaltData.new()
	pack.type = IngredientData.IngredientType.MALT
	pack.pack_grams = 100
	assert_eq(QuickScript.steps(kilo), QuickScript.KILO_STEPS)
	assert_eq(QuickScript.steps(pack), QuickScript.SMALL_PACK_STEPS)
	assert_eq(pack.amount_text(QuickScript.SMALL_PACK_STEPS[1]), "0.5", "five packs read as half a kilo")
	assert_eq(pack.amount_text(QuickScript.SMALL_PACK_STEPS[2]), "1.0", "and ten as a kilo")
	var half := MaltData.new()
	half.type = IngredientData.IngredientType.MALT
	half.pack_grams = 500
	assert_eq(QuickScript.steps(half), QuickScript.PACK_STEPS)
	assert_eq(QuickScript.max_units(kilo), QuickScript.MAX_UNITS)


func test_yeast_steps_in_pieces() -> void:
	var yeast := YeastData.new()
	yeast.type = IngredientData.IngredientType.YEAST
	assert_eq(QuickScript.steps(yeast), QuickScript.PIECE_STEPS)
