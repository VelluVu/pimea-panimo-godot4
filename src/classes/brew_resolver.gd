class_name BrewResolver
extends Resource


const BASE_STYLE_PRICE : float = 3.0
const STYLE_PRICE_COST_WEIGHT : float = 0.4
const MAX_STYLE_PRICE_BONUS : float = 4.0

var active_styles: Array[BeerStyle] = []
var _style_base_price_cache : Dictionary = {}


func _ready() -> void:
	_load_all_beer_styles()


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
		print(StringContainer.LOADED_BEER_STYLES_MESSAGE % str(active_styles.size()))
		for current_style in active_styles:
			print(current_style.get_style_string())


func resolve_brew_style(prep_contents : Dictionary) -> BrewResult:
	var total_malt_weight: int = 0
	var weighted_ebc_sum: float = 0
	var total_hop_amount: int = 0
	var total_alpha_acids: float = 0
	var total_beta_acids: float = 0
	var yeast_type: int = -1
	var distinct_hop_ids: Dictionary = {}
	var hop_profiles_used: Dictionary = {}

	for id in prep_contents.keys():
		var amount: int = prep_contents[id]
		var data: IngredientData = IngredientDatabase.database[id]

		match data.type:
			IngredientData.IngredientType.MALT:
				total_malt_weight += amount
				weighted_ebc_sum += data.ebc * amount
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


## Small per-style price differentiator derived from how much its own
## minimum recipe costs in raw ingredients — a hop-heavy style ends up
## priced a bit above a bare-bones malt+yeast one. Square-root dampened
## and capped (MAX_STYLE_PRICE_BONUS) so a style needing many grams of
## an expensive hop doesn't linearly dominate: this is meant to be a
## small nudge on top of BASE_STYLE_PRICE, not a second quality
## multiplier, and the whole sale economy runs on small rounded integers
## (see CustomerData.evaluate_brew_batch's roundi(income)). Cached per
## style since compute_minimum_ingredients() does a brute-force search.
func get_style_base_price(beer_style : BeerStyle) -> float:
	if _style_base_price_cache.has(beer_style.style):
		return _style_base_price_cache[beer_style.style]

	var ingredients : Dictionary = compute_minimum_ingredients(beer_style)
	var raw_cost : int = 0
	for ingredient_id : int in ingredients:
		var data : IngredientData = IngredientDatabase.database[ingredient_id]
		raw_cost += data.base_price * ingredients[ingredient_id]

	var bonus : float = clampf(sqrt(float(raw_cost)) * STYLE_PRICE_COST_WEIGHT, 0.0, MAX_STYLE_PRICE_BONUS)
	var price : float = BASE_STYLE_PRICE + bonus

	_style_base_price_cache[beer_style.style] = price
	return price


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_Style in active_styles:
		if beer_Style.style == style:
			return beer_Style
	
	return null


## Computes a bare-minimum ingredient combination that actually brews the
## given style — used to seed every unlocked style's default recipe.
## Returns {} if no valid combination could be found. Every result is
## re-checked against resolve_brew_style() itself before being returned,
## since active_styles is matched in load order and a combo built purely
## from beer_style's own ranges could otherwise land inside an earlier,
## wider-ranged style instead of the one it was built for.
func compute_minimum_ingredients(beer_style : BeerStyle) -> Dictionary:
	var combo : Dictionary = _find_malt_combo(beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight)
	if combo.is_empty():
		return {}

	combo[beer_style.required_yeast_id] = 1

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = _find_hop_dose(beer_style.min_ibu, beer_style.max_ibu, beer_style.preferred_hop_profile)
		if hop_dose.is_empty():
			return {}
		for hop_id in hop_dose:
			combo[hop_id] = hop_dose[hop_id]

	var result : BrewResult = resolve_brew_style(combo)
	if result == null or not result.is_matched or result.beer_style.style != beer_style.style:
		return {}

	return combo


func _get_all_malts() -> Array[MaltData]:
	var malts : Array[MaltData] = []
	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data is MaltData:
			malts.append(data)
	return malts


func _get_all_hops() -> Array[HopData]:
	var hops : Array[HopData] = []
	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data is HopData:
			hops.append(data)
	return hops


## Single malt first (cheapest, truest "bare minimum"); falls back to a
## brute-force two-malt blend search when no single malt's EBC lands in
## range — several styles in this project's data have no single-malt
## solution at all (e.g. Doppelbock's [71,95] EBC window sits strictly
## between the two closest malts), so the blend path is load-bearing,
## not an edge case.
func _find_malt_combo(min_ebc : int, max_ebc : int, min_weight : int) -> Dictionary:
	var malts := _get_all_malts()

	for malt in malts:
		if malt.ebc >= min_ebc and malt.ebc <= max_ebc:
			return {malt.id: min_weight}

	var target_ebc := (min_ebc + max_ebc) / 2.0
	var best_combo : Dictionary = {}
	var best_distance := INF
	var amount_cap := min_weight + 6

	for i in range(malts.size()):
		for j in range(malts.size()):
			if i == j:
				continue

			var malt_a : MaltData = malts[i]
			var malt_b : MaltData = malts[j]
			if malt_a.ebc >= malt_b.ebc:
				continue

			for amount_a in range(1, amount_cap):
				for amount_b in range(1, amount_cap):
					var total := amount_a + amount_b
					if total < min_weight:
						continue

					var avg := float(malt_a.ebc * amount_a + malt_b.ebc * amount_b) / total
					if avg < min_ebc or avg > max_ebc:
						continue

					var distance := absf(avg - target_ebc)
					if distance < best_distance:
						best_distance = distance
						best_combo = {malt_a.id: amount_a, malt_b.id: amount_b}

	return best_combo


## Single hop dose targeting the center of the style's IBU window,
## preferring one matching the style's flavor profile (falls back to any
## hop). Nudges the amount by up to 2g either way to land inside range
## when the center-target rounding falls just outside it.
func _find_hop_dose(min_ibu : int, max_ibu : int, preferred_profile : HopData.FlavorProfile) -> Dictionary:
	var hops := _get_all_hops()
	if hops.is_empty():
		return {}

	var preferred : Array[HopData] = []
	for hop in hops:
		if hop.flavor_profile == preferred_profile:
			preferred.append(hop)

	var candidates := preferred if not preferred.is_empty() else hops
	var target_ibu := (min_ibu + max_ibu) / 2.0

	var deltas : Array[int] = [0, 1, -1, 2, -2]

	for hop in candidates:
		var base_amount : int = max(1, roundi(target_ibu * 10.0 / hop.alpha_acids))
		for delta in deltas:
			var try_amount : int = base_amount + delta
			if try_amount < 1:
				continue

			var final_ibu := roundi(hop.alpha_acids * try_amount / 10.0)
			if final_ibu >= min_ibu and final_ibu <= max_ibu:
				return {hop.id: try_amount}

	return {}
