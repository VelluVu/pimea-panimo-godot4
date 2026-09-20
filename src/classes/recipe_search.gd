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


## One hop dose aimed at the middle of the IBU window, preferring the style's
## flavour profile. Nudges the amount by up to 2 to land inside the window.
static func find_hop_dose(hops : Array[HopData], min_ibu : int, max_ibu : int, preferred_profile : HopData.FlavorProfile) -> Dictionary:
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
