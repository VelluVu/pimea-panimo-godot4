class_name BrewMixture
extends RefCounted

## What is on the brewing table, boiled down to the totals a style is matched against.

const MIN_MALT_WEIGHT : int = 3
const NO_YEAST : int = -1
const NO_REQUIRED_MALT : int = -1
const ALPHA_ACIDS_PER_IBU : float = 10.0

## Kilograms of malt and sugar on the table.
var malt_weight : float = 0.0
var hop_amount : int = 0
var alpha_acids : float = 0.0
var beta_acids : float = 0.0
var yeast_id : int = NO_YEAST
var final_ebc : int = 0
var final_ibu : int = 0
var abv : float = 0.0
## Ids and profiles present with a non-zero amount, whatever the amount.
var malt_ids : Dictionary = {}
var hop_ids : Dictionary = {}
var hop_profiles : Dictionary = {}
var spice_ids : Dictionary = {}

## Malt id -> kg, for base malt shares.
var _malt_kg : Dictionary = {}
var _color_units : float = 0.0
var _gravity_points : float = 0.0
var _attenuation : float = 0.0


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
	if not beer_style.required_spice_ids.all(func(id : int) -> bool: return spice_ids.has(id)):
		return false
	if beer_style.requires_aroma_hop and not has_aroma_hop():
		return false
	if malt_weight < beer_style.min_malt_weight:
		return false
	if not beer_style.base_malt_ids.is_empty() and base_share(beer_style.base_malt_ids) < beer_style.min_base_share:
		return false
	return final_ebc >= beer_style.min_ebc and final_ebc <= beer_style.max_ebc \
			and final_ibu >= beer_style.min_ibu and final_ibu <= beer_style.max_ibu \
			and is_equal_approx(abv, clampf(abv, beer_style.min_abv, beer_style.max_abv))


## Share of the malt weight made of `ids`, 0 to 1.
func base_share(ids : Array[int]) -> float:
	if malt_weight <= 0.0:
		return 0.0
	var kg : float = 0.0
	for id : int in ids:
		kg += float(_malt_kg.get(id, 0.0))
	return kg / malt_weight


## True when at least one hop has an aroma of its own (any flavour profile).
func has_aroma_hop() -> bool:
	return hop_profiles.keys().any(func(profile : HopData.FlavorProfile) -> bool: return profile != HopData.FlavorProfile.NONE)


func _add(id : int, data : IngredientData, amount : int) -> void:
	match data.type:
		IngredientData.IngredientType.MALT:
			_add_malt(id, data as MaltData, amount)
		IngredientData.IngredientType.HOP:
			_add_hop(id, data as HopData, amount)
		IngredientData.IngredientType.YEAST:
			yeast_id = id
			if data is YeastData:
				_attenuation = (data as YeastData).attentuation_percent
		IngredientData.IngredientType.SPICE:
			if amount > 0:
				spice_ids[id] = true


func _add_malt(id : int, malt : MaltData, amount : int) -> void:
	if amount <= 0:
		return
	var kg : float = malt.kg(amount)
	malt_weight += kg
	_malt_kg[id] = float(_malt_kg.get(id, 0.0)) + kg
	_color_units += BrewFormulas.malt_color_units(kg, malt.ebc)
	_gravity_points += BrewFormulas.gravity_points(kg, malt.extract, malt.is_sugar)
	malt_ids[id] = true


func _add_hop(id : int, hop : HopData, amount : int) -> void:
	hop_amount += amount
	alpha_acids += hop.alpha_acids * amount
	beta_acids += hop.beta_acids * amount
	if amount > 0:
		hop_ids[id] = true
		hop_profiles[hop.flavor_profile] = true


func _compute_totals() -> void:
	final_ebc = roundi(BrewFormulas.ebc_from_color_units(_color_units))
	if hop_amount > 0:
		final_ibu = roundi(alpha_acids / ALPHA_ACIDS_PER_IBU)
	# One decimal, as the player sees it, so a range edge behaves the way it reads.
	abv = snappedf(BrewFormulas.abv(_gravity_points, _attenuation), 0.1)
