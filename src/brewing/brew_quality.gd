class_name BrewQuality
extends RefCounted

## How well a mixture hits a style it already fits: precision inside the EBC/IBU
## windows plus hop and spice bonuses, folded into one quality multiplier.

const PRECISION_WEIGHT : float = 0.4
const NEUTRAL_PRECISION : float = 0.5
const HOP_DIVERSITY_STEP : float = 0.05
const HOP_DIVERSITY_MAX : float = 0.15
const HOP_BALANCE_WEIGHT : float = 0.1
const FLAVOR_MATCH_BONUS : float = 0.1
const SPICE_MATCH_STEP : float = 0.05
const SPICE_MATCH_MAX : float = 0.1
const MIN_MULTIPLIER : float = 0.5
const MAX_MULTIPLIER : float = 1.5


## 1.0 at the middle of the window, 0.0 at its edges and beyond.
static func range_precision(value : float, min_v : float, max_v : float) -> float:
	if max_v <= min_v:
		return 1.0
	var center : float = (min_v + max_v) / 2.0
	var half_range : float = (max_v - min_v) / 2.0
	return clampf(1.0 - absf(value - center) / half_range, 0.0, 1.0)


static func precision_score(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	var ebc_precision : float = range_precision(mixture.final_ebc, beer_style.min_ebc, beer_style.max_ebc)
	var ibu_precision : float = range_precision(mixture.final_ibu, beer_style.min_ibu, beer_style.max_ibu)
	return (ebc_precision + ibu_precision) / 2.0


## Rewards a mix where alpha and beta acids are close to each other.
static func hop_balance_bonus(mixture : BrewMixture) -> float:
	if mixture.alpha_acids <= 0.0 or mixture.beta_acids <= 0.0:
		return 0.0
	var ratio : float = minf(mixture.alpha_acids, mixture.beta_acids) / maxf(mixture.alpha_acids, mixture.beta_acids)
	return ratio * HOP_BALANCE_WEIGHT


static func hop_diversity_bonus(mixture : BrewMixture) -> float:
	return clampf((mixture.hop_ids.size() - 1) * HOP_DIVERSITY_STEP, 0.0, HOP_DIVERSITY_MAX)


static func flavor_matched(mixture : BrewMixture, beer_style : BeerStyle) -> bool:
	if beer_style.required_spice_id != BrewMixture.NO_REQUIRED_SPICE and mixture.spice_ids.has(beer_style.required_spice_id):
		return true
	return beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE \
			and mixture.hop_profiles.has(beer_style.preferred_hop_profile)


static func spice_bonus(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	var matched : int = 0
	for spice_id : int in beer_style.preferred_spice_ids:
		if mixture.spice_ids.has(spice_id):
			matched += 1
	return minf(matched * SPICE_MATCH_STEP, SPICE_MATCH_MAX)


static func multiplier(mixture : BrewMixture, precision : float, balance_bonus : float, flavor_match : bool, spice_match_bonus : float = 0.0) -> float:
	var value : float = 1.0 + (precision - NEUTRAL_PRECISION) * PRECISION_WEIGHT
	value += hop_diversity_bonus(mixture) + balance_bonus + spice_match_bonus
	if flavor_match:
		value += FLAVOR_MATCH_BONUS
	return clampf(value, MIN_MULTIPLIER, MAX_MULTIPLIER)
