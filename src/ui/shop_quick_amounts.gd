class_name ShopQuickAmounts
extends RefCounted

## The shop's quick-amount buttons and the most one purchase can take, by how an
## ingredient is sold, so a phone needs a tap or two instead of a long slider drag.

const GRAM_STEPS : Array[int] = [10, 50, 100]
const KILO_STEPS : Array[int] = [1, 5]
## 100 g packs: 0.1, 0.5 and 1 kg, so Münchenin bought as a base malt is still quick.
const SMALL_PACK_STEPS : Array[int] = [1, 5, 10]
## 500 g packs: 0.5 and 2.5 kg.
const PACK_STEPS : Array[int] = [1, 5]
const SMALL_PACK_GRAMS : int = 100
const PIECE_STEPS : Array[int] = [1, 5]
## Hops go by the gram, so they need more room than kilos or packs.
const MAX_GRAMS : int = 250
const MAX_UNITS : int = 99


## The units each quick button adds, smallest first.
static func steps(ingredient : IngredientData) -> Array[int]:
	if ingredient.type == IngredientData.IngredientType.HOP:
		return GRAM_STEPS
	if ingredient is MaltData:
		match (ingredient as MaltData).pack_grams:
			1000: return KILO_STEPS
			SMALL_PACK_GRAMS: return SMALL_PACK_STEPS
			_: return PACK_STEPS
	return PIECE_STEPS


static func max_units(ingredient : IngredientData) -> int:
	return MAX_GRAMS if ingredient.type == IngredientData.IngredientType.HOP else MAX_UNITS
