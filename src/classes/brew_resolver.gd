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

var active_styles: Array[BeerStyle] = []
var _style_cost_per_bottle_cache : Dictionary = {}
var _sale_breakdown_cache : Dictionary = {}

## This run's ingredient price multiplier, set by Brewery so per-bottle costs match
## what the player actually pays.
var ingredient_price_multiplier : float = 1.0

## Optional ingredient table (id -> IngredientData) used instead of the
## IngredientDatabase autoload, which the test runner cannot reach. See use_ingredients().
var _injected_ingredients : Dictionary = {}
var _injected_ingredient_ids : Array[int] = []
var _has_injected_ingredients : bool = false


## Applies BOTTLE_LOSS_RATE; shared by brewing and the cost calculation.
static func get_effective_bottle_yield(raw_yield : int) -> int:
	return maxi(1, raw_yield - roundi(raw_yield * BOTTLE_LOSS_RATE))


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


func _ingredient_table() -> Dictionary:
	return _injected_ingredients if _has_injected_ingredients else IngredientDatabase.database


func _ingredient_ids() -> Array[int]:
	return _injected_ingredient_ids if _has_injected_ingredients else IngredientDatabase.sorted_ids


func _load_all_beer_styles() -> void:
	var path = StringContainer.PATH_TO_BREW_STYLES
	
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
		print(StringContainer.CREATED_MISSING_BEER_STYLES_FOLDER, path)
		return
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(StringContainer.RESOURCE_END) or file_name.ends_with(StringContainer.REMAP_END)):
				var clean_path = path + file_name.replace(StringContainer.REMAP_END, "")
				var style_resource = load(clean_path)
				
				if style_resource is BeerStyle:
					active_styles.append(style_resource)
					
			file_name = dir.get_next()
		dir.list_dir_end()
		_prioritize_required_malt_styles()
		print(StringContainer.LOADED_BEER_STYLES_MESSAGE % str(active_styles.size()))
		for current_style in active_styles:
			print(current_style.get_style_string())


## resolve_brew_style() is first-match-wins, so styles that require a specific malt go
## first: a wide catch-all like Pale Ale would otherwise swallow them by filename order.
## Order within each group is kept.
func _prioritize_required_malt_styles() -> void:
	var with_required_malt : Array[BeerStyle] = []
	var without_required_malt : Array[BeerStyle] = []
	for style in active_styles:
		if style.required_malt_id != -1:
			with_required_malt.append(style)
		else:
			without_required_malt.append(style)
	active_styles = with_required_malt + without_required_malt


func resolve_brew_style(prep_contents : Dictionary) -> BrewResult:
	var total_malt_weight: int = 0
	var weighted_ebc_sum: float = 0
	var total_hop_amount: int = 0
	var total_alpha_acids: float = 0
	var total_beta_acids: float = 0
	var yeast_type: int = -1
	var distinct_hop_ids: Dictionary = {}
	var hop_profiles_used: Dictionary = {}
	## Malt ids on the table, regardless of amount (see BeerStyle.required_malt_id).
	var malt_ids_used: Dictionary = {}

	for id in prep_contents.keys():
		var amount: int = prep_contents[id]
		var data: IngredientData = _ingredient_table()[id]

		match data.type:
			IngredientData.IngredientType.MALT:
				total_malt_weight += amount
				weighted_ebc_sum += data.ebc * amount
				if amount > 0:
					malt_ids_used[id] = true
			IngredientData.IngredientType.HOP:
				total_hop_amount += amount
				total_alpha_acids += (data.alpha_acids * amount)
				total_beta_acids += (data.beta_acids * amount)
				if amount > 0:
					distinct_hop_ids[id] = true
					hop_profiles_used[data.flavor_profile] = true
			IngredientData.IngredientType.YEAST:
				yeast_type = id

	if total_malt_weight < 3 or yeast_type == -1:
		print(StringContainer.NOT_ENOUGH_INGREDIENTS_ERROR)
		return null

	var final_ebc = roundi(weighted_ebc_sum / total_malt_weight)
	var final_ibu = 0
	if total_hop_amount > 0:
		final_ibu = roundi(total_alpha_acids / 10)

	for beer_style in active_styles:
		if yeast_type != beer_style.required_yeast_id:
			continue
		if beer_style.required_malt_id != -1 and not malt_ids_used.has(beer_style.required_malt_id):
			continue
		if total_malt_weight < beer_style.min_malt_weight:
			continue
		if final_ebc < beer_style.min_ebc or final_ebc > beer_style.max_ebc:
			continue
		if final_ibu < beer_style.min_ibu or final_ibu > beer_style.max_ibu:
			continue

		var ebc_precision := _range_precision(final_ebc, beer_style.min_ebc, beer_style.max_ebc)
		var ibu_precision := _range_precision(final_ibu, beer_style.min_ibu, beer_style.max_ibu)
		var precision_score := (ebc_precision + ibu_precision) / 2.0

		var distinct_hop_bonus := clampf((distinct_hop_ids.size() - 1) * 0.05, 0.0, 0.15)

		var hop_balance_bonus := 0.0
		if total_alpha_acids > 0.0 and total_beta_acids > 0.0:
			hop_balance_bonus = (min(total_alpha_acids, total_beta_acids) / max(total_alpha_acids, total_beta_acids)) * 0.1

		var flavor_matched := beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE and hop_profiles_used.has(beer_style.preferred_hop_profile)
		var flavor_match_bonus := 0.1 if flavor_matched else 0.0

		var quality_multiplier := 1.0 + (precision_score - 0.5) * 0.4 + distinct_hop_bonus + hop_balance_bonus + flavor_match_bonus
		quality_multiplier = clampf(quality_multiplier, 0.5, 1.5)

		var result := BrewResult.new()
		result.beer_style = beer_style
		result.final_ebc = final_ebc
		result.final_ibu = final_ibu
		result.original_quality = snappedf(beer_style.original_quality * quality_multiplier, 0.01)
		result.reputation_change = beer_style.reputation_change
		result.is_matched = true
		result.precision_score = precision_score
		result.hop_diversity_count = distinct_hop_ids.size()
		result.hop_balance_bonus = hop_balance_bonus
		result.flavor_matched = flavor_matched
		return result

	var failed_result := BrewResult.new()
	failed_result.beer_style = get_beer_style(BeerStyle.Style.KOTIKALJA)
	failed_result.final_ebc = final_ebc
	failed_result.final_ibu = final_ibu
	failed_result.original_quality = 1.0
	failed_result.reputation_change = -1
	failed_result.is_matched = false

	return failed_result


func _range_precision(value: float, min_v: float, max_v: float) -> float:
	if max_v <= min_v:
		return 1.0

	var center := (min_v + max_v) / 2.0
	var half_range := (max_v - min_v) / 2.0
	var distance := absf(value - center)

	return clampf(1.0 - (distance / half_range), 0.0, 1.0)


## Cost floor per bottle: the cheapest malt combo, the required yeast and the
## cheapest hop dose that clear the style's ranges, spread over one batch's yield,
## plus consumables. Deliberately not compute_minimum_ingredients(), which aims at
## the middle of the ranges and would price a wide-window style like IPA off an
## unrealistic hop dose. Cached per style, because the hop search is brute force.
func get_style_cost_per_bottle(beer_style : BeerStyle) -> float:
	if _style_cost_per_bottle_cache.has(beer_style.style):
		return _style_cost_per_bottle_cache[beer_style.style]

	var malt_combo : Dictionary = RecipeSearch.find_malt_combo(_get_all_malts(), beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight, beer_style.required_malt_id)
	var raw_cost : int = 0
	for malt_id : int in malt_combo:
		raw_cost += _ingredient_table()[malt_id].base_price * malt_combo[malt_id]

	var yeast_data : IngredientData = _ingredient_table().get(beer_style.required_yeast_id)
	if yeast_data != null:
		raw_cost += yeast_data.base_price

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = RecipeSearch.find_cheapest_hop_dose(_get_all_hops(), beer_style.min_ibu, beer_style.max_ibu)
		for hop_id : int in hop_dose:
			raw_cost += _ingredient_table()[hop_id].base_price * hop_dose[hop_id]

	var raw_yield : int = BrewResult.new().bottle_yield
	var effective_yield : int = get_effective_bottle_yield(raw_yield)
	var cost_per_bottle : float = ((float(raw_cost) * ingredient_price_multiplier) / float(effective_yield)) + LABEL_ART_COST_PER_BOTTLE + CONSUMABLES_COST_PER_BOTTLE

	_style_cost_per_bottle_cache[beer_style.style] = cost_per_bottle
	return cost_per_bottle


## price = raw cost + max(raw cost * PROFIT_MARKUP_RATE, MIN_PROFIT_PER_BOTTLE)
## * profit_margin_multiplier. Static and independent of IngredientDatabase so it can
## be unit-tested. `abv` is for display only.
static func calculate_price_breakdown(style_name : String, abv : float, raw_cost_per_bottle : float, profit_margin_multiplier : float = 1.0) -> SaleBreakdown:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = style_name
	breakdown.abv = abv
	breakdown.raw_cost_per_bottle = raw_cost_per_bottle

	var proportional_profit : float = raw_cost_per_bottle * PROFIT_MARKUP_RATE
	breakdown.profit_per_bottle = max(proportional_profit, MIN_PROFIT_PER_BOTTLE) * profit_margin_multiplier
	breakdown.price_per_bottle = breakdown.raw_cost_per_bottle + breakdown.profit_per_bottle

	return breakdown


## Cost plus margin, unless BeerStyle.fixed_price_per_bottle is set: then that price
## wins and the profit is whatever is left after cost. Cached per style.
func get_price_breakdown(beer_style : BeerStyle) -> SaleBreakdown:
	if _sale_breakdown_cache.has(beer_style.style):
		return _sale_breakdown_cache[beer_style.style]

	var raw_cost_per_bottle : float = get_style_cost_per_bottle(beer_style)
	var breakdown := calculate_price_breakdown(beer_style.style_name, beer_style.abv, raw_cost_per_bottle, beer_style.profit_margin_multiplier)

	if beer_style.fixed_price_per_bottle > 0.0:
		breakdown.price_per_bottle = beer_style.fixed_price_per_bottle
		breakdown.profit_per_bottle = breakdown.price_per_bottle - breakdown.raw_cost_per_bottle

	_sale_breakdown_cache[beer_style.style] = breakdown
	return breakdown


## The list price that a customer's evaluate_brew_batch() scales by quality, budget
## and preference.
func get_style_base_price(beer_style : BeerStyle) -> float:
	return get_price_breakdown(beer_style).price_per_bottle


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_Style in active_styles:
		if beer_Style.style == style:
			return beer_Style
	
	return null


## A bare-minimum combo that brews `beer_style`, used to seed default recipes; {} if
## none exists. Re-checked through resolve_brew_style(): styles match in load order,
## so a combo could land in an earlier, wider style instead.
func compute_minimum_ingredients(beer_style : BeerStyle) -> Dictionary:
	var combo : Dictionary = RecipeSearch.find_malt_combo(_get_all_malts(), beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight, beer_style.required_malt_id)
	if combo.is_empty():
		return {}

	combo[beer_style.required_yeast_id] = 1

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = RecipeSearch.find_hop_dose(_get_all_hops(), beer_style.min_ibu, beer_style.max_ibu, beer_style.preferred_hop_profile)
		if hop_dose.is_empty():
			return {}
		for hop_id in hop_dose:
			combo[hop_id] = hop_dose[hop_id]

	var result : BrewResult = resolve_brew_style(combo)
	if result == null or not result.is_matched or result.beer_style.style != beer_style.style:
		return {}

	return combo


## Whether the style's minimum combo needs a malt blend. Reuses
## compute_minimum_ingredients() so it always agrees with the seeded default recipe.
func style_needs_malt_blend(beer_style : BeerStyle) -> bool:
	var combo : Dictionary = compute_minimum_ingredients(beer_style)
	var malt_count : int = 0
	for id in combo:
		if _ingredient_table()[id].type == IngredientData.IngredientType.MALT:
			malt_count += 1
	return malt_count > 1


func _get_all_malts() -> Array[MaltData]:
	var malts : Array[MaltData] = []
	for id in _ingredient_ids():
		var data : IngredientData = _ingredient_table()[id]
		if data is MaltData:
			malts.append(data)
	return malts


func _get_all_hops() -> Array[HopData]:
	var hops : Array[HopData] = []
	for id in _ingredient_ids():
		var data : IngredientData = _ingredient_table()[id]
		if data is HopData:
			hops.append(data)
	return hops
