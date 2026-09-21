class_name BrewResolver
extends Resource


const FAILED_BREW_REPUTATION_CHANGE : int = -1
const FAILED_BREW_QUALITY : float = 1.0
const QUALITY_PRECISION : float = 0.01

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


## A bare-minimum combo that brews `beer_style`, used to seed default recipes; {} if
## none exists. Re-checked through resolve_brew_style(): styles match in load order,
## so a combo could land in an earlier, wider style instead.
func compute_minimum_ingredients(beer_style : BeerStyle) -> Dictionary:
	var combo : Dictionary = _ingredients.find_malt_combo(beer_style)
	if combo.is_empty():
		return {}
	combo[beer_style.required_yeast_id] = 1

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = RecipeSearch.find_hop_dose(_ingredients.all_hops(), beer_style.min_ibu, beer_style.max_ibu, beer_style.preferred_hop_profile)
		if hop_dose.is_empty():
			return {}
		combo.merge(hop_dose)

	var result : BrewResult = resolve_brew_style(combo)
	if result == null or not result.is_matched or result.beer_style.style != beer_style.style:
		return {}
	return combo


## Reuses compute_minimum_ingredients() so it always agrees with the seeded default recipe.
func style_needs_malt_blend(beer_style : BeerStyle) -> bool:
	var malt_count : int = 0
	for id : int in compute_minimum_ingredients(beer_style):
		if _ingredients.table()[id].type == IngredientData.IngredientType.MALT:
			malt_count += 1
	return malt_count > 1


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
	_prioritize_required_malt_styles()
	print(StringContainer.LOADED_BEER_STYLES_MESSAGE % str(active_styles.size()))


## resolve_brew_style() is first-match-wins, so styles that require a specific malt go
## first: a wide catch-all like Pale Ale would otherwise swallow them by filename order.
## Order within each group is kept.
func _prioritize_required_malt_styles() -> void:
	var requires_malt : Callable = func(beer_style : BeerStyle) -> bool:
		return beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT
	var with_required_malt : Array = active_styles.filter(requires_malt)
	var without_required_malt : Array = active_styles.filter(func(beer_style : BeerStyle) -> bool: return not requires_malt.call(beer_style))
	active_styles.assign(with_required_malt + without_required_malt)


func _build_match_result(mixture : BrewMixture, beer_style : BeerStyle) -> BrewResult:
	var precision : float = BrewQuality.precision_score(mixture, beer_style)
	var balance_bonus : float = BrewQuality.hop_balance_bonus(mixture)
	var flavor_matched : bool = BrewQuality.flavor_matched(mixture, beer_style)
	var multiplier : float = BrewQuality.multiplier(mixture, precision, balance_bonus, flavor_matched)

	var result := BrewResult.new()
	result.beer_style = beer_style
	result.final_ebc = mixture.final_ebc
	result.final_ibu = mixture.final_ibu
	result.original_quality = snappedf(beer_style.original_quality * multiplier, QUALITY_PRECISION)
	result.reputation_change = beer_style.reputation_change
	result.is_matched = true
	result.precision_score = precision
	result.hop_diversity_count = mixture.hop_ids.size()
	result.hop_balance_bonus = balance_bonus
	result.flavor_matched = flavor_matched
	return result


func _build_failed_result(mixture : BrewMixture) -> BrewResult:
	var result := BrewResult.new()
	result.beer_style = get_beer_style(BeerStyle.Style.KOTIKALJA)
	result.final_ebc = mixture.final_ebc
	result.final_ibu = mixture.final_ibu
	result.original_quality = FAILED_BREW_QUALITY
	result.reputation_change = FAILED_BREW_REPUTATION_CHANGE
	result.is_matched = false
	return result
