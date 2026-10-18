class_name BrewQuality
extends RefCounted

## How well a mixture hits a style it already fits, as one quality multiplier. Hop-forward
## styles (three or more hop marks) reward layered hopping; classic ones the colour,
## bitterness and strength more, and a hop layer less.

## How much hitting the middle of the EBC, IBU and ABV windows moves the quality.
const PRECISION_WEIGHT : float = 0.4
const CLASSIC_PRECISION_WEIGHT : float = 0.6
const NEUTRAL_PRECISION : float = 0.5
## A style with at least this many hop marks is hop-forward.
const HOP_FORWARD_MARKS : int = 3
## Quality per hop layer filled well: a high-alpha hop bittering, a hop of the style's
## preferred profile on each later mark.
const HOP_LAYER_STEP : float = 0.04
const CLASSIC_HOP_LAYER_STEP : float = 0.02
## A bittering hop counts as one at this alpha acid percentage (Magnum, Warrior, Citra).
const HIGH_ALPHA : int = 10
## A layer of fewer grams than this is a pinch, not a layer.
const MIN_LAYER_GRAMS : int = 5
const FLAVOR_MATCH_BONUS : float = 0.1
const SPICE_MATCH_STEP : float = 0.05
const SPICE_MATCH_MAX : float = 0.1
const PURITY_LAW_PENALTY : float = 0.1
## Per spice the style neither needs nor likes, so spicing a beer at random never pays.
const UNSUITED_SPICE_PENALTY : float = 0.05
## Per character malt of the style in the grist, capped.
const MALT_MATCH_STEP : float = 0.03
const MALT_MATCH_MAX : float = 0.06
## A recipe that fits the style but hits nothing of it well. A by-the-book recipe lands
## near 1.0, so quality well above that needs perks, Olutoppi talents or upgrades.
const BASE_MULTIPLIER : float = 0.6
const MIN_MULTIPLIER : float = 0.5
const MAX_MULTIPLIER : float = 1.5


## 1.0 at the middle of the window, 0.0 at its edges and beyond.
static func range_precision(value : float, min_v : float, max_v : float) -> float:
	if max_v <= min_v:
		return 1.0
	var center : float = (min_v + max_v) / 2.0
	var half_range : float = (max_v - min_v) / 2.0
	return clampf(1.0 - absf(value - center) / half_range, 0.0, 1.0)


## A style whose IBU starts at 0 can be brewed without hops: below the middle, less is never worse.
static func ibu_precision(ibu : float, min_ibu : float, max_ibu : float) -> float:
	if min_ibu <= 0.0 and ibu <= (min_ibu + max_ibu) / 2.0:
		return 1.0
	return range_precision(ibu, min_ibu, max_ibu)


static func is_hop_forward(beer_style : BeerStyle) -> bool:
	return beer_style.hop_additions.size() >= HOP_FORWARD_MARKS


## The style's hop layers (its boil and dry hop marks) the recipe fills well.
static func good_hop_layers(mixture : BrewMixture, beer_style : BeerStyle) -> int:
	var good : int = 0
	for mark : BoilMark in mixture.hop_marks(beer_style):
		var hop : HopData = mixture.ingredient(mark.ingredient_id) as HopData
		if hop == null or mark.grams < MIN_LAYER_GRAMS:
			continue
		if mark.kind == HopAddition.Kind.BITTERING:
			if is_good_bittering_hop(hop, beer_style):
				good += 1
		elif beer_style.has_preferred_hop_profile(hop.flavor_profile):
			good += 1
	return good


## Traditional styles are often bittered with their own aroma hop (a Czech pils is
## all Saaz), it just takes more grams.
static func is_good_bittering_hop(hop : HopData, beer_style : BeerStyle) -> bool:
	if hop.alpha_acids >= HIGH_ALPHA:
		return true
	return beer_style.has_preferred_hop_profile(hop.flavor_profile)


static func hop_layer_bonus(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	var step : float = HOP_LAYER_STEP if is_hop_forward(beer_style) else CLASSIC_HOP_LAYER_STEP
	return good_hop_layers(mixture, beer_style) * step


static func precision_weight(beer_style : BeerStyle) -> float:
	return PRECISION_WEIGHT if is_hop_forward(beer_style) else CLASSIC_PRECISION_WEIGHT


static func precision_score(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	var ebc_precision : float = range_precision(mixture.final_ebc, beer_style.min_ebc, beer_style.max_ebc)
	var ibu_score : float = ibu_precision(mixture.ibu_for(beer_style), beer_style.min_ibu, beer_style.max_ibu)
	var abv_precision : float = range_precision(mixture.abv, beer_style.min_abv, beer_style.max_abv)
	return (ebc_precision + ibu_score + abv_precision) / 3.0


static func flavor_matched(mixture : BrewMixture, beer_style : BeerStyle) -> bool:
	if beer_style.required_spice_ids.any(func(id : int) -> bool: return mixture.spice_ids.has(id)):
		return true
	return mixture.hop_profiles.keys().any(beer_style.has_preferred_hop_profile)


## Negative when a spice breaks the style's Reinheitsgebot.
static func spice_bonus(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	if beer_style.forbids_spices and not mixture.spice_ids.is_empty():
		return -PURITY_LAW_PENALTY
	var matched : int = 0
	for spice_id : int in beer_style.preferred_spice_ids:
		if mixture.spice_ids.has(spice_id):
			matched += 1
	return minf(matched * SPICE_MATCH_STEP, SPICE_MATCH_MAX)


## Quality lost to spices that do not suit the style. German styles pay the Reinheitsgebot
## in spice_bonus() instead.
static func unsuited_spice_penalty(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	if beer_style.forbids_spices:
		return 0.0
	var unsuited : int = 0
	for spice_id : int in mixture.spice_ids:
		if not beer_style.preferred_spice_ids.has(spice_id) and not beer_style.required_spice_ids.has(spice_id):
			unsuited += 1
	return unsuited * UNSUITED_SPICE_PENALTY


static func malt_bonus(mixture : BrewMixture, beer_style : BeerStyle) -> float:
	var matched : int = beer_style.preferred_malt_ids.filter(func(id : int) -> bool: return mixture.malt_ids.has(id)).size()
	return minf(matched * MALT_MATCH_STEP, MALT_MATCH_MAX)


static func multiplier(beer_style : BeerStyle, precision : float, layer_bonus : float, flavor_match : bool, spice_match_bonus : float = 0.0, malt_match_bonus : float = 0.0) -> float:
	var value : float = BASE_MULTIPLIER + (precision - NEUTRAL_PRECISION) * precision_weight(beer_style)
	value += layer_bonus + spice_match_bonus + malt_match_bonus
	if flavor_match:
		value += FLAVOR_MATCH_BONUS
	return clampf(value, MIN_MULTIPLIER, MAX_MULTIPLIER)
