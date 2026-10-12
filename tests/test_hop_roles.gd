@tool
extends McpTestSuite

const HopRolesScript := preload("res://src/brewing/brew_day/hop_roles.gd")

const MAGNUM_ID : int = 200
const CASCADE_ID : int = 201
const CITRA_ID : int = 202
const CORIANDER_ID : int = 401
const MALT_ID : int = 101


func suite_name() -> String:
	return "hop_roles"


func _hop(id : int, alpha : int, profile : HopData.FlavorProfile) -> HopData:
	var hop := HopData.new()
	hop.id = id
	hop.type = IngredientData.IngredientType.HOP
	hop.alpha_acids = alpha
	hop.flavor_profile = profile
	return hop


func _table() -> Dictionary:
	var spice := IngredientData.new()
	spice.id = CORIANDER_ID
	spice.type = IngredientData.IngredientType.SPICE
	var malt := MaltData.new()
	malt.id = MALT_ID
	malt.type = IngredientData.IngredientType.MALT
	return {
		MAGNUM_ID: _hop(MAGNUM_ID, 16, HopData.FlavorProfile.EARTHY),
		CASCADE_ID: _hop(CASCADE_ID, 6, HopData.FlavorProfile.CITRUS),
		CITRA_ID: _hop(CITRA_ID, 12, HopData.FlavorProfile.TROPICAL),
		CORIANDER_ID: spice,
		MALT_ID: malt,
	}


func _kinds(list : Array) -> Array[HopAddition.Kind]:
	var kinds : Array[HopAddition.Kind] = []
	kinds.assign(list)
	return kinds


func test_the_most_bitter_hop_bitters() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({MAGNUM_ID: 20, CASCADE_ID: 30, MALT_ID: 5}, _table(),
		_kinds([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA]), HopData.FlavorProfile.CITRUS)
	assert_eq(marks.size(), 2)
	assert_eq(marks[0].kind, HopAddition.Kind.BITTERING)
	assert_eq(marks[0].ingredient_id, MAGNUM_ID)
	assert_eq(marks[0].grams, 20)
	assert_eq(marks[1].ingredient_id, CASCADE_ID)


func test_the_preferred_flavour_goes_to_the_late_marks() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({MAGNUM_ID: 20, CITRA_ID: 10, CASCADE_ID: 10}, _table(),
		_kinds([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA]), HopData.FlavorProfile.CITRUS)
	var aroma : Array = marks.filter(func(mark : BoilMark) -> bool: return mark.kind == HopAddition.Kind.AROMA)
	assert_eq(aroma[0].ingredient_id, CASCADE_ID)
	# Citra has no mark of its own, so it joins the last one.
	assert_eq(aroma.size(), 2)


func test_one_hop_is_split_over_every_mark() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({CASCADE_ID: 31}, _table(),
		_kinds([HopAddition.Kind.BITTERING, HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA]), HopData.FlavorProfile.CITRUS)
	assert_eq(marks.size(), 3)
	var total : int = 0
	for mark : BoilMark in marks:
		assert_eq(mark.ingredient_id, CASCADE_ID)
		total += mark.grams
	assert_eq(total, 31)
	assert_eq(marks[0].grams, 11)


func test_a_style_without_hop_marks_still_boils_its_hops() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({CASCADE_ID: 10}, _table(), _kinds([]), HopData.FlavorProfile.NONE)
	assert_eq(marks.size(), 1)
	assert_eq(marks[0].kind, HopAddition.Kind.BITTERING)


func test_no_hops_means_no_hop_marks() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({MALT_ID: 5}, _table(),
		_kinds([HopAddition.Kind.BITTERING]), HopData.FlavorProfile.NONE)
	assert_true(marks.is_empty())


func test_spices_get_their_own_mark_and_the_dry_hop_comes_last() -> void:
	var marks : Array[BoilMark] = HopRolesScript.assign({MAGNUM_ID: 20, CASCADE_ID: 20, CORIANDER_ID: 2}, _table(),
		_kinds([HopAddition.Kind.BITTERING, HopAddition.Kind.DRY_HOP]), HopData.FlavorProfile.CITRUS)
	assert_eq(marks.size(), 3)
	assert_eq(marks[1].kind, HopAddition.Kind.SPICE)
	assert_eq(marks[1].grams, 2)
	assert_eq(marks[2].kind, HopAddition.Kind.DRY_HOP)
