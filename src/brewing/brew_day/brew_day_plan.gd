class_name BrewDayPlan
extends RefCounted

## Everything one brew day needs, read from the style and the brewing table once: the
## mash steps, the boil's marks and sacks, and the colour of the liquid.

const WHEAT_MALT_ID : int = 103

var style_name : String = ""
var ebc : int = 0
var mash_steps : Array[float] = []
var mash_band : float = MashSession.BAND
var dough_in_clumps : int = MashSession.CLUMPS_AT_DOUGH_IN
var burner_lag : float = MashSession.BURNER_LAG
var gram_tolerance : float = BoilSession.GRAM_TOLERANCE
## The boil's marks only; the dry hop goes in by itself in the fermentor.
var marks : Array[BoilMark] = []
## Ingredient ids tapped in whole instead of poured by weight.
var piece_ids : Array[int] = []
## Ingredient id -> display name, for the sacks.
var names : Dictionary = {}
## All the malts together, for the malt sack.
var malt_kg : int = 0


## `table` maps ingredient id -> IngredientData.
static func create(style : BeerStyle, contents : Dictionary, table : Dictionary, final_ebc : int) -> BrewDayPlan:
	var plan := BrewDayPlan.new()
	plan.style_name = style.style_name
	plan.ebc = final_ebc
	for temperature : int in style.mash_steps:
		plan.mash_steps.append(float(temperature))
	plan.mash_band = style.mash_band
	# Wheat has no husk to keep the mash loose, so it clumps more.
	if int(contents.get(WHEAT_MALT_ID, 0)) > 0:
		plan.dough_in_clumps += MashSession.WHEAT_EXTRA_CLUMPS
	for mark : BoilMark in HopRoles.assign(contents, table, style.hop_additions, style.preferred_hop_profile):
		if BoilSchedule.is_in_boil(mark.kind):
			plan.marks.append(mark)
	for id : int in contents:
		var data : IngredientData = table.get(id)
		if data == null:
			continue
		plan.names[id] = data.name
		if data.type == IngredientData.IngredientType.MALT:
			plan.malt_kg += int(contents[id])
		if data.unit == IngredientData.UnitType.PIECE:
			plan.piece_ids.append(id)
	return plan


## The sacks in the order their first mark comes.
func sack_ids() -> Array[int]:
	var ids : Array[int] = []
	for mark : BoilMark in marks:
		if not ids.has(mark.ingredient_id):
			ids.append(mark.ingredient_id)
	return ids


func new_mash(rng : RandomNumberGenerator = null) -> MashSession:
	return MashSession.new(mash_steps, mash_band, burner_lag, dough_in_clumps, rng)


func new_boil() -> BoilSession:
	# Fresh marks, so a retried brew day starts with none of them judged.
	var fresh : Array[BoilMark] = []
	for mark : BoilMark in marks:
		var copy := BoilMark.new(mark.kind, mark.ingredient_id, mark.grams)
		copy.bittering_only = mark.bittering_only
		fresh.append(copy)
	var boil := BoilSession.new(fresh, piece_ids, burner_lag)
	boil.gram_tolerance = gram_tolerance
	return boil
