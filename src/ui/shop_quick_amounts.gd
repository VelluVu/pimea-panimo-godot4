class_name ShopQuickAmounts
extends RefCounted

## The shop's quick-amount buttons and the most one purchase can take, by how an
## ingredient is sold, so a phone needs a tap or two instead of a long slider drag.

const GRAM_STEPS : Array[int] = [10, 25, 100]
const KILO_STEPS : Array[int] = [1, 5]
## One and five packs: 0.1 and 0.5 kg of 100 g packs, 0.5 and 2.5 kg of 500 g packs.
const PACK_STEPS : Array[int] = [1, 5]
const PIECE_STEPS : Array[int] = [1, 5]
## Hops go by the gram, so they need more room than kilos or packs.
const MAX_GRAMS : int = 250
const MAX_UNITS : int = 99


## The units each quick button adds, smallest first.
static func steps(ingredient : IngredientData) -> Array[int]:
	if ingredient.type == IngredientData.IngredientType.HOP:
		return GRAM_STEPS
	if ingredient is MaltData:
		return KILO_STEPS if (ingredient as MaltData).pack_grams == 1000 else PACK_STEPS
	return PIECE_STEPS


static func max_units(ingredient : IngredientData) -> int:
	return MAX_GRAMS if ingredient.type == IngredientData.IngredientType.HOP else MAX_UNITS
