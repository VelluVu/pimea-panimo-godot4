class_name BrewMixture
extends RefCounted

## What is on the brewing table, boiled down to the totals a style is matched against.

const MIN_MALT_WEIGHT : int = 3
const NO_YEAST : int = -1
const NO_REQUIRED_MALT : int = -1
const ALPHA_ACIDS_PER_IBU : float = 10.0

var malt_weight : int = 0
var hop_amount : int = 0
var alpha_acids : float = 0.0
var beta_acids : float = 0.0
var yeast_id : int = NO_YEAST
var final_ebc : int = 0
var final_ibu : int = 0
## Ids and profiles present with a non-zero amount, whatever the amount.
var malt_ids : Dictionary = {}
var hop_ids : Dictionary = {}
var hop_profiles : Dictionary = {}

var _weighted_ebc_sum : float = 0.0


## `contents` is id -> amount; `ingredients` is id -> IngredientData.
static func from_contents(contents : Dictionary, ingredients : Dictionary) -> BrewMixture:
	var mixture := BrewMixture.new()
	for id : int in contents:
		mixture._add(id, ingredients[id], contents[id])
	mixture._compute_totals()
	return mixture


func is_brewable() -> bool:
	return malt_weight >= MIN_MALT_WEIGHT and yeast_id != NO_YEAST


func fits(beer_style : BeerStyle) -> bool:
	if yeast_id != beer_style.required_yeast_id:
		return false
	if beer_style.required_malt_id != NO_REQUIRED_MALT and not malt_ids.has(beer_style.required_malt_id):
		return false
	if malt_weight < beer_style.min_malt_weight:
		return false
	return final_ebc >= beer_style.min_ebc and final_ebc <= beer_style.max_ebc \
			and final_ibu >= beer_style.min_ibu and final_ibu <= beer_style.max_ibu


func _add(id : int, data : IngredientData, amount : int) -> void:
	match data.type:
		IngredientData.IngredientType.MALT:
			_add_malt(id, data as MaltData, amount)
		IngredientData.IngredientType.HOP:
			_add_hop(id, data as HopData, amount)
		IngredientData.IngredientType.YEAST:
			yeast_id = id


func _add_malt(id : int, malt : MaltData, amount : int) -> void:
	malt_weight += amount
	_weighted_ebc_sum += malt.ebc * amount
	if amount > 0:
		malt_ids[id] = true


func _add_hop(id : int, hop : HopData, amount : int) -> void:
	hop_amount += amount
	alpha_acids += hop.alpha_acids * amount
	beta_acids += hop.beta_acids * amount
	if amount > 0:
		hop_ids[id] = true
		hop_profiles[hop.flavor_profile] = true


func _compute_totals() -> void:
	if malt_weight > 0:
		final_ebc = roundi(_weighted_ebc_sum / malt_weight)
	if hop_amount > 0:
		final_ibu = roundi(alpha_acids / ALPHA_ACIDS_PER_IBU)
