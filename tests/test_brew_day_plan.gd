@tool
extends McpTestSuite

const BrewDayPlanScript := preload("res://src/brewing/brew_day/brew_day_plan.gd")

const HOP_ID : int = 200
const SPICE_ID : int = 401


func suite_name() -> String:
	return "brew_day_plan"


func _table() -> Dictionary:
	var hop := HopData.new()
	hop.id = HOP_ID
	hop.name = "Magnum-humala"
	hop.type = IngredientData.IngredientType.HOP
	hop.unit = IngredientData.UnitType.GRAM
	hop.alpha_acids = 16
	var wheat := MaltData.new()
	wheat.id = BrewDayPlanScript.WHEAT_MALT_ID
	wheat.type = IngredientData.IngredientType.MALT
	var spice := IngredientData.new()
	spice.id = SPICE_ID
	spice.type = IngredientData.IngredientType.SPICE
	spice.unit = IngredientData.UnitType.PIECE
	return {HOP_ID: hop, BrewDayPlanScript.WHEAT_MALT_ID: wheat, SPICE_ID: spice}


func _style() -> BeerStyle:
	var style := BeerStyle.new()
	style.style_name = "Witbier"
	style.mash_steps.assign([45, 63, 72])
	style.hop_additions.assign([HopAddition.Kind.BITTERING, HopAddition.Kind.DRY_HOP])
	return style


func test_the_plan_reads_the_style_and_table() -> void:
	var plan : BrewDayPlan = BrewDayPlanScript.create(_style(), {HOP_ID: 40, BrewDayPlanScript.WHEAT_MALT_ID: 4, SPICE_ID: 1}, _table(), 8)
	assert_eq(plan.mash_steps.size(), 3)
	assert_eq(plan.mash_steps[2], 72.0)
	assert_eq(plan.ebc, 8)
	assert_eq(plan.dough_in_clumps, MashSession.CLUMPS_AT_DOUGH_IN + MashSession.WHEAT_EXTRA_CLUMPS)
	assert_true(plan.piece_ids.has(SPICE_ID))
	assert_false(plan.piece_ids.has(HOP_ID))


func test_the_malt_sack_counts_only_the_malts() -> void:
	var plan : BrewDayPlan = BrewDayPlanScript.create(_style(), {HOP_ID: 40, BrewDayPlanScript.WHEAT_MALT_ID: 4, SPICE_ID: 1}, _table(), 8)
	assert_eq(plan.malt_kg, 4.0)


func test_the_dry_hop_leaves_the_boil_marks() -> void:
	var plan : BrewDayPlan = BrewDayPlanScript.create(_style(), {HOP_ID: 40}, _table(), 8)
	assert_eq(plan.marks.size(), 1)
	assert_eq(plan.marks[0].kind, HopAddition.Kind.BITTERING)
	assert_eq(plan.marks[0].grams, 20)
	assert_eq(plan.sack_ids().size(), 1)
	assert_eq(plan.sack_ids()[0], HOP_ID)


func test_each_boil_gets_fresh_marks() -> void:
	var plan : BrewDayPlan = BrewDayPlanScript.create(_style(), {HOP_ID: 40}, _table(), 8)
	var first : BoilSession = plan.new_boil()
	first.marks[0].result = BoilMark.Result.FULL
	var second : BoilSession = plan.new_boil()
	assert_eq(second.marks[0].result, BoilMark.Result.OPEN)
	assert_eq(plan.marks[0].result, BoilMark.Result.OPEN)


func test_a_fresh_boil_keeps_the_bittering_only_flag() -> void:
	var style : BeerStyle = _style()
	style.hop_additions.assign([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA])
	var table : Dictionary = _table()
	(table[HOP_ID] as HopData).flavor_profile = HopData.FlavorProfile.NONE
	var plan : BrewDayPlan = BrewDayPlanScript.create(style, {HOP_ID: 40}, table, 8)
	var boil : BoilSession = plan.new_boil()
	assert_true(boil.marks[1].bittering_only)
