class_name BrewResolver
extends Resource


## Share of a batch's raw bottles lost to breakage. Applied to real batches and to
## the per-bottle cost, so the two agree.
const BOTTLE_LOSS_RATE : float = 0.05
## Label cost per bottle produced (before loss): paid when brewing and part of the cost basis.
const LABEL_ART_COST_PER_BOTTLE : float = 0.05
## Bottle, cap and cleaner cost per bottle, in the same cost basis.
const CONSUMABLES_COST_PER_BOTTLE : float = 0.10

## Profit margin as a markup on raw cost. There is no tax in this model: a hidden
## cellar remits nothing.
const PROFIT_MARKUP_RATE : float = 0.5
## Floor under the proportional margin, so cheap styles like Kotikalja still show a
## real profit.
const MIN_PROFIT_PER_BOTTLE : float = 0.5

const FAILED_BREW_REPUTATION_CHANGE : int = -1
const FAILED_BREW_QUALITY : float = 1.0
const QUALITY_PRECISION : float = 0.01

var active_styles : Array[BeerStyle] = []
## This run's ingredient price multiplier, set by Brewery so per-bottle costs match
## what the player actually pays.
var ingredient_price_multiplier : float = 1.0

var _style_cost_per_bottle_cache : Dictionary = {}
var _sale_breakdown_cache : Dictionary = {}

## Optional ingredient table (id -> IngredientData) used instead of the
## IngredientDatabase autoload, which the test runner cannot reach. See use_ingredients().
var _injected_ingredients : Dictionary = {}
var _injected_ingredient_ids : Array[int] = []
var _has_injected_ingredients : bool = false


## Applies BOTTLE_LOSS_RATE; shared by brewing and the cost calculation.
static func get_effective_bottle_yield(raw_yield : int) -> int:
	return maxi(1, raw_yield - roundi(raw_yield * BOTTLE_LOSS_RATE))


## price = raw cost + max(raw cost * PROFIT_MARKUP_RATE, MIN_PROFIT_PER_BOTTLE)
## * profit_margin_multiplier. Static and independent of IngredientDatabase so it can
## be unit-tested. `abv` is for display only.
static func calculate_price_breakdown(style_name : String, abv : float, raw_cost_per_bottle : float, profit_margin_multiplier : float = 1.0) -> SaleBreakdown:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = style_name
	breakdown.abv = abv
	breakdown.raw_cost_per_bottle = raw_cost_per_bottle
	var proportional_profit : float = raw_cost_per_bottle * PROFIT_MARKUP_RATE
	breakdown.profit_per_bottle = maxf(proportional_profit, MIN_PROFIT_PER_BOTTLE) * profit_margin_multiplier
	breakdown.price_per_bottle = raw_cost_per_bottle + breakdown.profit_per_bottle
	return breakdown


func _ready() -> void:
	_load_all_beer_styles()


## Makes this resolver read ingredients from `table` (id -> IngredientData)
## instead of IngredientDatabase. Ids are iterated in ascending order, the
## same order IngredientDatabase.sorted_ids gives.
func use_ingredients(table : Dictionary) -> void:
	_injected_ingredients = table
	_injected_ingredient_ids.clear()
	for id : int in table.keys():
		_injected_ingredient_ids.append(id)
	_injected_ingredient_ids.sort()
	_has_injected_ingredients = true


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_style : BeerStyle in active_styles:
		if beer_style.style == style:
			return beer_style
	return null


func resolve_brew_style(prep_contents : Dictionary) -> BrewResult:
	var mixture := BrewMixture.from_contents(prep_contents, _ingredient_table())
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
	var combo : Dictionary = _find_malt_combo(beer_style)
	if combo.is_empty():
		return {}
	combo[beer_style.required_yeast_id] = 1

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = RecipeSearch.find_hop_dose(_get_all_hops(), beer_style.min_ibu, beer_style.max_ibu, beer_style.preferred_hop_profile)
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
		if _ingredient_table()[id].type == IngredientData.IngredientType.MALT:
			malt_count += 1
	return malt_count > 1


## Cost floor per bottle, cached per style because the hop search is brute force.
func get_style_cost_per_bottle(beer_style : BeerStyle) -> float:
	if _style_cost_per_bottle_cache.has(beer_style.style):
		return _style_cost_per_bottle_cache[beer_style.style]

	var effective_yield : int = get_effective_bottle_yield(BrewResult.new().bottle_yield)
	var ingredient_cost : float = _cheapest_recipe_cost(beer_style) * ingredient_price_multiplier
	var cost_per_bottle : float = ingredient_cost / effective_yield + LABEL_ART_COST_PER_BOTTLE + CONSUMABLES_COST_PER_BOTTLE
	_style_cost_per_bottle_cache[beer_style.style] = cost_per_bottle
	return cost_per_bottle


## Cost plus margin, unless BeerStyle.fixed_price_per_bottle is set: then that price
## wins and the profit is whatever is left after cost. Cached per style.
func get_price_breakdown(beer_style : BeerStyle) -> SaleBreakdown:
	if _sale_breakdown_cache.has(beer_style.style):
		return _sale_breakdown_cache[beer_style.style]

	var breakdown := calculate_price_breakdown(beer_style.style_name, beer_style.abv, get_style_cost_per_bottle(beer_style), beer_style.profit_margin_multiplier)
	if beer_style.fixed_price_per_bottle > 0.0:
		breakdown.price_per_bottle = beer_style.fixed_price_per_bottle
		breakdown.profit_per_bottle = breakdown.price_per_bottle - breakdown.raw_cost_per_bottle
	_sale_breakdown_cache[beer_style.style] = breakdown
	return breakdown


## The list price that a customer's evaluate_brew_batch() scales by quality, budget
## and preference.
func get_style_base_price(beer_style : BeerStyle) -> float:
	return get_price_breakdown(beer_style).price_per_bottle


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


## The cheapest malt combo, the required yeast and the cheapest hop dose that clear the
## style's ranges. Deliberately not compute_minimum_ingredients(), which aims at the
## middle of the ranges and would price a wide-window style like IPA off an unrealistic
## hop dose.
func _cheapest_recipe_cost(beer_style : BeerStyle) -> float:
	var cost : int = _combo_cost(_find_malt_combo(beer_style))

	var yeast_data : IngredientData = _ingredient_table().get(beer_style.required_yeast_id)
	if yeast_data != null:
		cost += yeast_data.base_price

	if beer_style.min_ibu > 0:
		cost += _combo_cost(RecipeSearch.find_cheapest_hop_dose(_get_all_hops(), beer_style.min_ibu, beer_style.max_ibu))
	return cost


func _combo_cost(combo : Dictionary) -> int:
	var cost : int = 0
	for id : int in combo:
		cost += _ingredient_table()[id].base_price * combo[id]
	return cost


func _find_malt_combo(beer_style : BeerStyle) -> Dictionary:
	return RecipeSearch.find_malt_combo(_get_all_malts(), beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight, beer_style.required_malt_id)


func _ingredient_table() -> Dictionary:
	return _injected_ingredients if _has_injected_ingredients else IngredientDatabase.database


func _ingredient_ids() -> Array[int]:
	return _injected_ingredient_ids if _has_injected_ingredients else IngredientDatabase.sorted_ids


func _all_ingredients() -> Array:
	return _ingredient_ids().map(func(id : int) -> IngredientData: return _ingredient_table()[id])


func _get_all_malts() -> Array[MaltData]:
	var malts : Array[MaltData] = []
	malts.assign(_all_ingredients().filter(func(data : IngredientData) -> bool: return data is MaltData))
	return malts


func _get_all_hops() -> Array[HopData]:
	var hops : Array[HopData] = []
	hops.assign(_all_ingredients().filter(func(data : IngredientData) -> bool: return data is HopData))
	return hops
