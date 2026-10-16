@tool
extends McpTestSuite

## Unit tests for BrewDayLook: the brew day's colours, steam, warmth and boil loop.

const LookScript := preload("res://src/ui/brew_day/brew_day_look.gd")
const BoilMarkScript := preload("res://src/brewing/brew_day/boil_mark.gd")


func suite_name() -> String:
	return "brew_day_look"


func _mark(id : int, kind : HopAddition.Kind) -> BoilMark:
	var mark : BoilMark = BoilMarkScript.new()
	mark.ingredient_id = id
	mark.kind = kind
	return mark


func test_pellets_take_their_marks_colour() -> void:
	assert_eq(LookScript.pellet_color(_mark(5, HopAddition.Kind.BITTERING)), LookScript.PELLET_COLORS[HopAddition.Kind.BITTERING])
	assert_eq(LookScript.pellet_color(_mark(5, HopAddition.Kind.AROMA)), LookScript.PELLET_COLORS[HopAddition.Kind.AROMA])
	assert_eq(LookScript.pellet_color(_mark(5, HopAddition.Kind.DRY_HOP)), LookScript.PELLET_COLORS[HopAddition.Kind.FLAVOR], "no colour of its own falls back to flavour")
	assert_eq(LookScript.pellet_color(_mark(BrewDayLines.JUNIPER_ID, HopAddition.Kind.FLAVOR)), LookScript.JUNIPER_COLOR)


func test_sack_name_drops_the_hop_ending() -> void:
	assert_eq(LookScript.sack_name("Citra-humala"), "Citra")
	assert_eq(LookScript.sack_name("Kataja"), "Kataja")


func test_the_burner_warms_over_the_last_degrees_to_the_target() -> void:
	assert_eq(LookScript.warmth(40.0, 67.0), 0.0)
	assert_eq(LookScript.warmth(67.0, 67.0), 1.0)
	assert_eq(LookScript.warmth(67.0 - LookScript.WARM_SPAN / 2.0, 67.0), 0.5)


func test_the_pour_clouds_the_water_and_the_blend_finishes_it() -> void:
	assert_eq(LookScript.mash_cloud(0.0, 0.0, false), 0.0)
	assert_eq(LookScript.mash_cloud(1.0, 0.0, false), LookScript.POUR_CLOUD)
	assert_eq(LookScript.mash_cloud(1.0, 0.0, true), LookScript.POUR_CLOUD, "no jump when the malts go in")
	assert_eq(LookScript.mash_cloud(1.0, 1.0, true), 1.0)
	assert_eq(LookScript.mash_murk(0.0), LookScript.WATER_MURK)
	assert_true(is_equal_approx(LookScript.mash_murk(1.0), LookScript.MASH_MURK))


func test_steam_grows_toward_and_through_the_boil() -> void:
	assert_eq(LookScript.mash_steam(20.0), 0.0)
	assert_eq(LookScript.mash_steam(80.0), LookScript.MASH_STEAM)
	assert_eq(LookScript.boil_steam(BoilSession.BOIL_MIN - 20.0, false, 0.0), 0.0)
	assert_eq(LookScript.boil_steam(BoilSession.BOIL_MIN, false, 0.0), LookScript.NEAR_BOIL_STEAM)
	assert_eq(LookScript.boil_steam(BoilSession.BOIL_MIN, true, 0.0), LookScript.BOIL_STEAM)
	assert_true(LookScript.boil_steam(BoilSession.BOIL_MIN, true, 1.0) > LookScript.BOIL_STEAM, "foam thickens it")


func test_the_boil_loop_is_silent_until_it_boils_and_grows_with_the_foam() -> void:
	assert_eq(LookScript.boil_loop(false, 1.0), 0.0)
	assert_eq(LookScript.boil_loop(true, 0.0), LookScript.BOIL_SOUND_BASE)
	assert_eq(LookScript.boil_loop(true, 2.0), 1.0)
