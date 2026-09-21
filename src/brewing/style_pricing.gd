class_name StylePricing
extends RefCounted

## What a style costs to make and what it sells for. Results are cached per style,
## because the hop search behind the cost is brute force.

## Share of a batch's raw bottles lost to breakage, in real batches and in the cost.
const BOTTLE_LOSS_RATE : float = 0.05
## Per bottle produced (before loss): paid when brewing and part of the cost basis.
const LABEL_ART_COST_PER_BOTTLE : float = 0.05
const CONSUMABLES_COST_PER_BOTTLE : float = 0.10

## Profit as a markup on raw cost. No tax: a hidden cellar remits nothing.
const PROFIT_MARKUP_RATE : float = 0.5
## Floor under the markup, so cheap styles like Kotikalja still show a real profit.
const MIN_PROFIT_PER_BOTTLE : float = 0.5

## Set by Brewery per run, so costs match what the player pays.
var ingredient_price_multiplier : float = 1.0

var _ingredients : IngredientSource
var _cost_cache : Dictionary = {}
var _breakdown_cache : Dictionary = {}


func _init(ingredients : IngredientSource) -> void:
	_ingredients = ingredients


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


func cost_per_bottle(beer_style : BeerStyle) -> float:
	if _cost_cache.has(beer_style.style):
		return _cost_cache[beer_style.style]

	var effective_yield : int = get_effective_bottle_yield(BrewResult.new().bottle_yield)
	var ingredient_cost : float = _cheapest_recipe_cost(beer_style) * ingredient_price_multiplier
	var cost : float = ingredient_cost / effective_yield + LABEL_ART_COST_PER_BOTTLE + CONSUMABLES_COST_PER_BOTTLE
	_cost_cache[beer_style.style] = cost
	return cost


## Cost plus margin, unless BeerStyle.fixed_price_per_bottle is set: then that price
## wins and the profit is whatever is left after cost.
func price_breakdown(beer_style : BeerStyle) -> SaleBreakdown:
	if _breakdown_cache.has(beer_style.style):
		return _breakdown_cache[beer_style.style]

	var breakdown := calculate_price_breakdown(beer_style.style_name, beer_style.abv, cost_per_bottle(beer_style), beer_style.profit_margin_multiplier)
	if beer_style.fixed_price_per_bottle > 0.0:
		breakdown.price_per_bottle = beer_style.fixed_price_per_bottle
		breakdown.profit_per_bottle = breakdown.price_per_bottle - breakdown.raw_cost_per_bottle
	_breakdown_cache[beer_style.style] = breakdown
	return breakdown


## The cheapest malt combo, the required yeast and the cheapest hop dose that clear the
## style's ranges. Deliberately not BrewResolver.compute_minimum_ingredients(), which
## aims at the middle of the ranges and would price a wide-window style like IPA off an
## unrealistic hop dose.
func _cheapest_recipe_cost(beer_style : BeerStyle) -> int:
	var cost : int = _ingredients.combo_cost(_ingredients.find_malt_combo(beer_style))

	var yeast_data : IngredientData = _ingredients.table().get(beer_style.required_yeast_id)
	if yeast_data != null:
		cost += yeast_data.base_price

	if beer_style.min_ibu > 0:
		cost += _ingredients.combo_cost(RecipeSearch.find_cheapest_hop_dose(_ingredients.all_hops(), beer_style.min_ibu, beer_style.max_ibu))
	return cost
