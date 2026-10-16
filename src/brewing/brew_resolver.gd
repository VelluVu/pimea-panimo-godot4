class_name BrewResolver
extends Resource


const FAILED_BREW_REPUTATION_CHANGE : int = -1
const FAILED_BREW_QUALITY : float = 1.0
const QUALITY_PRECISION : float = 0.01

const LOG_LOADED_STYLES : String = "Ladattu yhteensä %s oluttyyliä datasta:"

var active_styles : Array[BeerStyle] = []
## Forwarded to StylePricing; Brewery sets it per run.
var ingredient_price_multiplier : float:
	get:
		return _pricing.ingredient_price_multiplier
	set(value):
		_pricing.ingredient_price_multiplier = value

var _ingredients := IngredientSource.new()
var _pricing : StylePricing


func _init() -> void:
	_pricing = StylePricing.new(_ingredients)


func _ready() -> void:
	_load_all_beer_styles()


## Reads ingredients from `table` (id -> IngredientData) instead of IngredientDatabase.
func use_ingredients(table : Dictionary) -> void:
	_ingredients.inject(table)


## Ingredient id -> IngredientData, the injected table or IngredientDatabase's.
func ingredient_table() -> Dictionary:
	return _ingredients.table()


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_style : BeerStyle in active_styles:
		if beer_style.style == style:
			return beer_style
	return null


func resolve_brew_style(prep_contents : Dictionary) -> BrewResult:
	var mixture := BrewMixture.from_contents(prep_contents, _ingredients.table())
	if not mixture.is_brewable():
		print(StringContainer.NOT_ENOUGH_INGREDIENTS_ERROR)
		return null

	for beer_style : BeerStyle in active_styles:
		if mixture.fits(beer_style):
			return _build_match_result(mixture, beer_style)
	return _build_failed_result(mixture)


## The style's reference recipe, used to seed default recipes; {} if it is missing or no
## longer brews the style (re-checked, since styles are first-match-wins).
func compute_minimum_ingredients(beer_style : BeerStyle) -> Dictionary:
	if beer_style.reference_recipe.is_empty():
		return {}
	var recipe : Dictionary = {}
	recipe.merge(beer_style.reference_recipe)
	var result : BrewResult = resolve_brew_style(recipe)
	if result == null or not result.is_matched or result.beer_style.style != beer_style.style:
		return {}
	return recipe


## Kilograms of malt in the style's reference recipe, for the mash tun (MashTun).
func reference_malt_weight(beer_style : BeerStyle) -> float:
	return BrewMixture.from_contents(beer_style.reference_recipe, _ingredients.table()).malt_weight


## True when the reference recipe uses more than one malt.
func style_needs_malt_blend(beer_style : BeerStyle) -> bool:
	var malt_count : int = 0
	for id : int in beer_style.reference_recipe:
		var data : IngredientData = _ingredients.table().get(id)
		if data != null and data.type == IngredientData.IngredientType.MALT:
			malt_count += 1
	return malt_count > 1


## What a bar pays per serving, see StylePricing.wholesale_price_per_bottle().
func get_wholesale_price_per_bottle(beer_style : BeerStyle) -> float:
	return _pricing.wholesale_price_per_bottle(beer_style)


func get_style_cost_per_bottle(beer_style : BeerStyle) -> float:
	return _pricing.cost_per_bottle(beer_style)


func get_price_breakdown(beer_style : BeerStyle) -> SaleBreakdown:
	return _pricing.price_breakdown(beer_style)


## The list price that a customer's evaluate_brew_batch() scales by quality, budget
## and preference.
func get_style_base_price(beer_style : BeerStyle) -> float:
	return _pricing.price_breakdown(beer_style).price_per_bottle


func _load_all_beer_styles() -> void:
	active_styles.assign(ResourceFolder.load_all(StringContainer.PATH_TO_BREW_STYLES, BeerStyle))
	prioritize_styles()
	print(LOG_LOADED_STYLES % str(active_styles.size()))


## resolve_brew_style() is first-match-wins, so the most specific styles go first (see
## BeerStyle.match_priority()): a wide style would otherwise swallow them by filename
## order. Order within each group is kept.
func prioritize_styles() -> void:
	var ordered : Array[BeerStyle] = []
	for priority : int in 3:
		ordered.append_array(active_styles.filter(func(beer_style : BeerStyle) -> bool: return beer_style.match_priority() == priority))
	active_styles = ordered


func _build_match_result(mixture : BrewMixture, beer_style : BeerStyle) -> BrewResult:
	var precision : float = BrewQuality.precision_score(mixture, beer_style)
	var balance_bonus : float = BrewQuality.hop_balance_bonus(mixture)
	var flavor_matched : bool = BrewQuality.flavor_matched(mixture, beer_style)
	var spice_bonus : float = BrewQuality.spice_bonus(mixture, beer_style)
	var unsuited_spice_penalty : float = BrewQuality.unsuited_spice_penalty(mixture, beer_style)
	var multiplier : float = BrewQuality.multiplier(mixture, precision, balance_bonus, flavor_matched, spice_bonus - unsuited_spice_penalty)

	var result := BrewResult.new()
	result.beer_style = beer_style
	result.final_ebc = mixture.final_ebc
	result.final_ibu = mixture.ibu_for(beer_style)
	result.original_quality = snappedf(beer_style.original_quality * multiplier, QUALITY_PRECISION)
	result.reputation_change = beer_style.reputation_change
	result.abv = mixture.abv
	result.malt_weight = mixture.malt_weight
	result.is_matched = true
	result.precision_score = precision
	result.hop_diversity_count = mixture.hop_ids.size()
	result.hop_balance_bonus = balance_bonus
	result.flavor_matched = flavor_matched
	result.spice_bonus = spice_bonus
	result.unsuited_spice_penalty = unsuited_spice_penalty
	return result


func _build_failed_result(mixture : BrewMixture) -> BrewResult:
	var result := BrewResult.new()
	result.beer_style = get_beer_style(BeerStyle.Style.KOTIKALJA)
	result.final_ebc = mixture.final_ebc
	result.final_ibu = mixture.final_ibu
	result.original_quality = FAILED_BREW_QUALITY
	result.reputation_change = FAILED_BREW_REPUTATION_CHANGE
	result.abv = mixture.abv
	result.malt_weight = mixture.malt_weight
	result.is_matched = false
	return result
