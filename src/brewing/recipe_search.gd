class_name RecipeSearch
extends RefCounted

## Pure ingredient-search maths: which malts and hops make a style's EBC and
## IBU ranges. Every function takes the candidate ingredients as arguments and
## touches no autoload or state, so it can be unit-tested with hand-built
## ingredients.


## A single malt whose EBC fits, else the two-malt blend closest to the middle
## of the EBC window (some styles, like Doppelbock, have no single-malt answer).
## `required_malt_id` (-1 for none) forces that malt into the result, see
## BeerStyle.required_malt_id.
static func find_malt_combo(malts : Array[MaltData], min_ebc : int, max_ebc : int, min_weight : int, required_malt_id : int = -1) -> Dictionary:
	if required_malt_id != -1:
		return _find_malt_combo_with_required(malts, min_ebc, max_ebc, min_weight, required_malt_id)

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


## The required malt alone if its EBC fits, else blended with each other malt
## in turn.
static func _find_malt_combo_with_required(malts : Array[MaltData], min_ebc : int, max_ebc : int, min_weight : int, required_malt_id : int) -> Dictionary:
	var required_malt : MaltData = null
	for malt in malts:
		if malt.id == required_malt_id:
			required_malt = malt
			break

	if required_malt == null:
		return {}

	if required_malt.ebc >= min_ebc and required_malt.ebc <= max_ebc:
		return {required_malt.id: min_weight}

	var target_ebc := (min_ebc + max_ebc) / 2.0
	var best_combo : Dictionary = {}
	var best_distance := INF
	var amount_cap := min_weight + 6

	for other_malt in malts:
		if other_malt.id == required_malt.id:
			continue

		for amount_required in range(1, amount_cap):
			for amount_other in range(1, amount_cap):
				var total := amount_required + amount_other
				if total < min_weight:
					continue

				var avg := float(required_malt.ebc * amount_required + other_malt.ebc * amount_other) / total
				if avg < min_ebc or avg > max_ebc:
					continue

				var distance := absf(avg - target_ebc)
				if distance < best_distance:
					best_distance = distance
					best_combo = {required_malt.id: amount_required, other_malt.id: amount_other}

	return best_combo


## Units of the flavour hop in a default recipe: the flavour bonus only needs the
## profile present, so a small dose keeps a low-alpha aroma hop affordable.
const FLAVOR_HOP_DOSE : int = 2
## Caps the IBU target for wide windows (IPA is 40-200), which would otherwise
## aim at a needlessly large and expensive dose.
const MAX_TARGET_ABOVE_MIN_IBU : float = 20.0


## A default recipe's hops, brewed the way a real brewer would: a small dose of the
## style's flavour hop plus the cheapest bittering hop (lowest price per alpha) to reach
## the IBU target. Only hops that need no reputation are picked for flavour, so the
## recipe can always be bought; without one the recipe simply skips the flavour bonus.
static func find_hop_dose(hops : Array[HopData], min_ibu : int, max_ibu : int, preferred_profile : HopData.FlavorProfile) -> Dictionary:
	var bittering : HopData = _cheapest_per_alpha(hops)
	if bittering == null:
		return {}

	var dose : Dictionary = {}
	var flavor_alpha : int = 0
	var flavor : HopData = _cheapest_unlocked_with_profile(hops, preferred_profile)
	if flavor != null:
		dose[flavor.id] = FLAVOR_HOP_DOSE
		flavor_alpha = flavor.alpha_acids * FLAVOR_HOP_DOSE

	var target_ibu : float = minf((min_ibu + max_ibu) / 2.0, min_ibu + MAX_TARGET_ABOVE_MIN_IBU)
	var base_amount : int = maxi(0, roundi((target_ibu * 10.0 - flavor_alpha) / bittering.alpha_acids))
	for delta : int in [0, 1, -1, 2, -2]:
		var try_amount : int = base_amount + delta
		if try_amount < 0 or (try_amount == 0 and dose.is_empty()):
			continue
		var final_ibu : int = roundi((flavor_alpha + bittering.alpha_acids * try_amount) / 10.0)
		if final_ibu >= min_ibu and final_ibu <= max_ibu:
			if try_amount > 0:
				dose[bittering.id] = dose.get(bittering.id, 0) + try_amount
			return dose
	return {}


static func _cheapest_per_alpha(hops : Array[HopData]) -> HopData:
	var best : HopData = null
	for hop in hops:
		if hop.alpha_acids <= 0 or hop.min_reputation > 0:
			continue
		if best == null or float(hop.base_price) / hop.alpha_acids < float(best.base_price) / best.alpha_acids:
			best = hop
	return best


static func _cheapest_unlocked_with_profile(hops : Array[HopData], profile : HopData.FlavorProfile) -> HopData:
	if profile == HopData.FlavorProfile.NONE:
		return null
	var best : HopData = null
	for hop in hops:
		if hop.flavor_profile != profile or hop.min_reputation > 0:
			continue
		if best == null or hop.base_price < best.base_price:
			best = hop
	return best


## The cheapest single hop dose that clears min_ibu, ignoring flavour: the real
## cost floor of brewing the style.
static func find_cheapest_hop_dose(hops : Array[HopData], min_ibu : int, max_ibu : int) -> Dictionary:
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
