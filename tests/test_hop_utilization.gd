@tool
extends McpTestSuite

## Unit tests for HopUtilization: late hops bitter less, like Tinseth's boil-time curve.

const UtilizationScript := preload("res://src/brewing/hop_utilization.gd")
const BoilMarkScript := preload("res://src/brewing/brew_day/boil_mark.gd")

const HOP_ID : int = 200


func suite_name() -> String:
	return "hop_utilization"


func test_bittering_is_the_full_boil_and_later_marks_bitter_less() -> void:
	assert_eq(UtilizationScript.of(HopAddition.Kind.BITTERING), 1.0)
	var flavor : float = UtilizationScript.of(HopAddition.Kind.FLAVOR)
	var aroma : float = UtilizationScript.of(HopAddition.Kind.AROMA)
	assert_true(absf(flavor - 0.5) < 0.02, "15 minutes is about half of an hour's: %f" % flavor)
	assert_true(absf(aroma - 0.1) < 0.02, "the flame-out stand is about a tenth: %f" % aroma)
	assert_eq(UtilizationScript.of(HopAddition.Kind.DRY_HOP), 0.0)
	assert_eq(UtilizationScript.of(HopAddition.Kind.SPICE), 0.0)


func test_ibu_weighs_each_mark_by_its_timing() -> void:
	var hop := HopData.new()
	hop.id = HOP_ID
	hop.alpha_acids = 10
	var table : Dictionary = {HOP_ID: hop}
	var bittering : Array[BoilMark] = [BoilMarkScript.new(HopAddition.Kind.BITTERING, HOP_ID, 30)]
	assert_eq(UtilizationScript.ibu(bittering, table), 30, "a full boil keeps the old alpha x grams / 10")
	var late : Array[BoilMark] = [BoilMarkScript.new(HopAddition.Kind.FLAVOR, HOP_ID, 30), BoilMarkScript.new(HopAddition.Kind.DRY_HOP, HOP_ID, 30)]
	assert_eq(UtilizationScript.ibu(late, table), 15, "the dry hop adds nothing")


func test_spice_marks_add_no_bitterness() -> void:
	var spice := IngredientData.new()
	var marks : Array[BoilMark] = [BoilMarkScript.new(HopAddition.Kind.SPICE, 401, 2)]
	assert_eq(UtilizationScript.ibu(marks, {401: spice}), 0)
