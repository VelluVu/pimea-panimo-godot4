class_name BrewMixture
extends RefCounted

## What is on the brewing table, boiled down to the totals a style is matched against.

const MIN_MALT_WEIGHT : int = 3
const NO_YEAST : int = -1
const NO_REQUIRED_MALT : int = -1
const ALPHA_ACIDS_PER_IBU : float = 10.0
## More hop varieties than this in one beer do not fit any style.
const MAX_HOP_VARIETIES : int = 3

## Kilograms of malt and sugar on the table.
var malt_weight : float = 0.0
var hop_amount : int = 0
var alpha_acids : float = 0.0
var beta_acids : float = 0.0
var yeast_id : int = NO_YEAST
var final_ebc : int = 0
## Bitterness if every hop boiled the whole hour; a style's own timing gives ibu_for().
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
var _contents : Dictionary = {}
var _table : Dictionary = {}
## Style -> its hop marks (HopRoles), and the IBU they give.
var _style_marks : Dictionary = {}
var _style_ibu : Dictionary = {}


## `contents` is id -> amount; `ingredients` is id -> IngredientData.
static func from_contents(contents : Dictionary, ingredients : Dictionary) -> BrewMixture:
	var mixture := BrewMixture.new()
	mixture._contents = contents
	mixture._table = ingredients
	for id : int in contents:
		mixture._add(id, ingredients[id], contents[id])
	mixture._compute_totals()
	return mixture


## Whether adding `id` would put one hop variety too many on the table; more of a hop
## already there is fine. Maps as in from_contents().
static func would_exceed_hop_varieties(id : int, contents : Dictionary, ingredients : Dictionary) -> bool:
	if not ingredients.get(id) is HopData or contents.has(id):
		return false
	var hops : int = contents.keys().filter(func(other : int) -> bool: return ingredients.get(other) is HopData).size()
	return hops >= MAX_HOP_VARIETIES


func is_brewable() -> bool:
	return malt_weight >= MIN_MALT_WEIGHT and yeast_id != NO_YEAST


func fits(beer_style : BeerStyle) -> bool:
	if hop_ids.size() > MAX_HOP_VARIETIES:
		return false
	if yeast_id != beer_style.required_yeast_id:
		return false
	if beer_style.required_malt_id != NO_REQUIRED_MALT and not malt_ids.has(beer_style.required_malt_id):
		return false
	if not beer_style.required_spice_ids.all(func(id : int) -> bool: return spice_ids.has(id)):
		return false
	if beer_style.requires_aroma_hop and not has_aroma_hop():
		return false
	if not beer_style.only_hop_ids.is_empty() and (hop_ids.is_empty() or not hop_ids.keys().all(beer_style.only_hop_ids.has)):
		return false
	if malt_weight < beer_style.min_malt_weight:
		return false
	if not beer_style.base_malt_ids.is_empty() and base_share(beer_style.base_malt_ids) < beer_style.min_base_share:
		return false
	return final_ebc >= beer_style.min_ebc and final_ebc <= beer_style.max_ebc \
			and ibu_for(beer_style) >= beer_style.min_ibu and ibu_for(beer_style) <= beer_style.max_ibu \
			and is_equal_approx(abv, clampf(abv, beer_style.min_abv, beer_style.max_abv))


## Bitterness as this style brews it: HopRoles puts each hop on one of the style's marks,
## and late marks bitter less (HopUtilization).
func ibu_for(beer_style : BeerStyle) -> int:
	if hop_amount <= 0:
		return 0
	if not _style_ibu.has(beer_style):
		_style_ibu[beer_style] = HopUtilization.ibu(hop_marks(beer_style), _table)
	return _style_ibu[beer_style]


## Which hop goes on which of the style's marks, and how much (HopRoles).
func hop_marks(beer_style : BeerStyle) -> Array[BoilMark]:
	if not _style_marks.has(beer_style):
		_style_marks[beer_style] = HopRoles.assign(_contents, _table, beer_style.hop_additions, beer_style.preferred_hop_profiles)
	return _style_marks[beer_style]


## The ingredient table this mixture was built from, id -> IngredientData.
func ingredient(id : int) -> IngredientData:
	return _table.get(id)


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
