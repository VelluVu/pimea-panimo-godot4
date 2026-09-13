class_name BrewResolver
extends Resource


## Fraction of a batch's raw bottle_yield that never makes it to sellable
## inventory — breakage/spillage during bottling. Applied for real in
## Brewery.start_brew() (fewer bottles actually land in inventory) and
## folded into get_style_cost_per_bottle() below (the same ingredient
## spend divided across fewer bottles costs more per bottle), so the two
## never drift apart.
const BOTTLE_LOSS_RATE : float = 0.05
## Label design/printing cost per bottle produced (before loss) — a real
## cash cost Brewery.start_brew() deducts from money, and also folded into
## the cost basis get_price_breakdown() marks up from, same reasoning as
## BOTTLE_LOSS_RATE above.
const LABEL_ART_COST_PER_BOTTLE : float = 0.05
## Bottle, cap, and cleaning-solution cost per bottle — the other
## production consumable besides label art, folded into the same cost
## basis for the same reason.
const CONSUMABLES_COST_PER_BOTTLE : float = 0.10

## Target profit margin: a markup on top of raw ingredient cost. No excise
## duty or VAT anywhere in this pricing model — a hidden cellar operation
## isn't remitting anything to the state, so there's nothing to mark up
## for or split off at sale time (see calculate_price_breakdown() and
## SaleBreakdown). Tunable balance constant.
const PROFIT_MARKUP_RATE : float = 0.5
## Absolute floor under PROFIT_MARKUP_RATE's proportional cut — on a cheap
## style like Kotikalja (raw cost ~0.36 EUR) the proportional margin alone
## is a few cents, which doesn't read as a real "kate" even though the
## actual sale rounds up to at least 1 EUR. Multiplied by
## profit_margin_multiplier same as the proportional term below (though
## that term already dominates for anything but the very cheapest styles).
const MIN_PROFIT_PER_BOTTLE : float = 0.5

var active_styles: Array[BeerStyle] = []
var _style_cost_per_bottle_cache : Dictionary = {}
var _sale_breakdown_cache : Dictionary = {}

## Set once by Brewery._init() right after this resolver is created, from
## this run's RunModifier.ingredient_price_multiplier — kept in sync with
## what Brewery._on_buy_ingredient() actually charges so get_style_cost_per_bottle()
## and the sale receipt's raw_cost_per_bottle never drift from what the
## player is really paying under a pricier/cheaper-ingredients modifier.
var ingredient_price_multiplier : float = 1.0


## Shared by Brewery.start_brew() (actually shrinking a real batch) and
## get_style_cost_per_bottle() (pricing off the same shrinkage) so
## BOTTLE_LOSS_RATE is applied identically in both places.
static func get_effective_bottle_yield(raw_yield : int) -> int:
	return maxi(1, raw_yield - roundi(raw_yield * BOTTLE_LOSS_RATE))


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


## Per-bottle production cost floor for a style: the cheapest malt combo
## that clears its EBC/weight requirement, its required yeast, and the
## cheapest hop dose that clears its min_ibu (see _find_cheapest_hop_dose),
## amortized over one batch's bottle yield, plus the flat per-bottle
## consumables (label art, bottle/cap/cleaner). Deliberately NOT
## compute_minimum_ingredients() (which targets the *center* of the style's
## EBC/IBU windows for the best brew precision/flavor-match bonus — great
## for seeding a default recipe, but a style with a wide IBU window like
## IPA [40,200] would then cost itself off a huge, unrealistic hop dose
## meant for a precision score, not a shopping list). Exposed separately
## from get_price_breakdown() (which marks this up with tax and profit) so
## both the dev console's "sell" preview and the price formula share one
## cost source instead of drifting apart. Cached per style since the hop
## search is brute-force.
func get_style_cost_per_bottle(beer_style : BeerStyle) -> float:
	if _style_cost_per_bottle_cache.has(beer_style.style):
		return _style_cost_per_bottle_cache[beer_style.style]

	var malt_combo : Dictionary = _find_malt_combo(beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight)
	var raw_cost : int = 0
	for malt_id : int in malt_combo:
		raw_cost += IngredientDatabase.database[malt_id].base_price * malt_combo[malt_id]

	var yeast_data : IngredientData = IngredientDatabase.database.get(beer_style.required_yeast_id)
	if yeast_data != null:
		raw_cost += yeast_data.base_price

	if beer_style.min_ibu > 0:
		var hop_dose : Dictionary = _find_cheapest_hop_dose(beer_style.min_ibu, beer_style.max_ibu)
		for hop_id : int in hop_dose:
			raw_cost += IngredientDatabase.database[hop_id].base_price * hop_dose[hop_id]

	var raw_yield : int = BrewResult.new().bottle_yield
	var effective_yield : int = get_effective_bottle_yield(raw_yield)
	var cost_per_bottle : float = ((float(raw_cost) * ingredient_price_multiplier) / float(effective_yield)) + LABEL_ART_COST_PER_BOTTLE + CONSUMABLES_COST_PER_BOTTLE

	_style_cost_per_bottle_cache[beer_style.style] = cost_per_bottle
	return cost_per_bottle


## Pure math, deliberately independent of IngredientDatabase (unlike
## get_style_cost_per_bottle) so it's unit-testable on its own — see
## tests/test_brew_resolver.gd. No excise duty or VAT: this cellar
## operation doesn't remit anything to the state, so the price is exactly
## what it costs to make plus a profit margin, full stop:
##   profit           = max(raw_cost * PROFIT_MARKUP_RATE, MIN_PROFIT_PER_BOTTLE) * profit_margin_multiplier
##   price_per_bottle = raw_cost + profit
## abv is carried through purely for display (batch labels, receipts) —
## it no longer affects price at all. profit_margin_multiplier is
## BeerStyle.profit_margin_multiplier (defaults to 1.0) — lets fussier,
## more complex styles like IPA or Imperial Stout still earn a fatter
## margin than a plain Kotikalja; the proportional term already dominates
## there, MIN_PROFIT_PER_BOTTLE only rescues the cheapest styles.
static func calculate_price_breakdown(style_name : String, abv : float, raw_cost_per_bottle : float, profit_margin_multiplier : float = 1.0) -> SaleBreakdown:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = style_name
	breakdown.abv = abv
	breakdown.raw_cost_per_bottle = raw_cost_per_bottle

	var proportional_profit : float = raw_cost_per_bottle * PROFIT_MARKUP_RATE
	breakdown.profit_per_bottle = max(proportional_profit, MIN_PROFIT_PER_BOTTLE) * profit_margin_multiplier
	breakdown.price_per_bottle = breakdown.raw_cost_per_bottle + breakdown.profit_per_bottle

	return breakdown


## Full per-bottle price breakdown for a style — raw ingredient cost (see
## get_style_cost_per_bottle) marked up with a target profit margin (see
## calculate_price_breakdown), UNLESS BeerStyle.fixed_price_per_bottle is
## set, in which case that hand-tuned price wins outright and "kate" is
## whatever's left after raw cost — price is the designed anchor here, not
## a formula output. Cached per style, same reasoning as
## get_style_cost_per_bottle.
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


## Per-style list price a customer's evaluate_brew_batch() multiplies by
## quality/budget/preference — see CustomerManager.process_auto_sale() and
## CustomerData.evaluate_brew_batch's price_modifier branches for how this
## turns into what a customer actually pays.
func get_style_base_price(beer_style : BeerStyle) -> float:
	return get_price_breakdown(beer_style).price_per_bottle


## Cost-only hop pick used solely by get_style_base_price — unlike
## _find_hop_dose (which targets the center of [min_ibu, max_ibu] for the
## best precision score and prefers preferred_hop_profile for the flavor
## bonus), this ignores flavor profile entirely and searches every hop for
## whichever one clears min_ibu for the lowest gram cost, since that's the
## real floor cost to brew a style at all.
func _find_cheapest_hop_dose(min_ibu : int, max_ibu : int) -> Dictionary:
	var hops := _get_all_hops()
	var deltas : Array[int] = [0, 1, 2, -1, 3, -2, 4, 5]

	var best_cost : int = -1
	var best_dose : Dictionary = {}

	for hop in hops:
		var base_amount : int = max(1, roundi(min_ibu * 10.0 / hop.alpha_acids))
		for delta in deltas:
			var try_amount : int = base_amount + delta
			if try_amount < 1:
				continue

			var final_ibu := roundi(hop.alpha_acids * try_amount / 10.0)
			if final_ibu >= min_ibu and final_ibu <= max_ibu:
				var cost : int = hop.base_price * try_amount
				if best_cost == -1 or cost < best_cost:
					best_cost = cost
					best_dose = {hop.id: try_amount}
				break

	return best_dose


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
