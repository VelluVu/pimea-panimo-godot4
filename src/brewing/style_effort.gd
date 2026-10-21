class_name StyleEffort
extends RefCounted

## How much work a style takes, counted from its data, so the recipe book can list the
## undiscovered styles easiest first.

enum Tier { EASY, MEDIUM, HARD }

## Per mash step past the first: each one is another stop on the brew day.
const EXTRA_MASH_STEP_POINTS : int = 2
## Per hop addition past the first.
const EXTRA_HOP_ADDITION_POINTS : int = 1
## A required malt, spice or hop narrows what fits.
const REQUIREMENT_POINTS : int = 2
## An ingredient the shop sells only at higher reputation.
const GATED_INGREDIENT_POINTS : int = 2
const MASH_UPGRADE_POINTS : int = 3
const MEDIUM_FROM : int = 8
const HARD_FROM : int = 12


## `table` is ingredient id -> IngredientData.
static func score(beer_style : BeerStyle, table : Dictionary, needs_mash_upgrade : bool) -> int:
	var points : int = beer_style.reference_recipe.size()
	points += maxi(0, beer_style.mash_steps.size() - 1) * EXTRA_MASH_STEP_POINTS
	points += maxi(0, beer_style.hop_additions.size() - 1) * EXTRA_HOP_ADDITION_POINTS
	if beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT:
		points += REQUIREMENT_POINTS
	if not beer_style.required_spice_ids.is_empty():
		points += REQUIREMENT_POINTS
	if not beer_style.only_hop_ids.is_empty():
		points += REQUIREMENT_POINTS
	if beer_style.reference_recipe.keys().any(func(id : int) -> bool: return table.has(id) and (table[id] as IngredientData).min_reputation > 0):
		points += GATED_INGREDIENT_POINTS
	if needs_mash_upgrade:
		points += MASH_UPGRADE_POINTS
	return points


static func tier(points : int) -> Tier:
	if points >= HARD_FROM:
		return Tier.HARD
	return Tier.MEDIUM if points >= MEDIUM_FROM else Tier.EASY
