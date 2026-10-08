class_name IngredientBookText
extends RefCounted

## The Panimokirja's Ainekset tab: a header per ingredient type and, per ingredient, its
## price, when it unlocks, its description and stats.

const MALT_HEADER : String = "Maltaat"
const HOP_HEADER : String = "Humalat"
const YEAST_HEADER : String = "Hiivat"
const SPICE_HEADER : String = "Mausteet"
const PRICE_FORMAT : String = "Hinta: %.2f € / %s"
const LOCKED_FORMAT : String = "Avautuu maineella %d"


static func type_header(type : IngredientData.IngredientType) -> String:
	match type:
		IngredientData.IngredientType.HOP:
			return UiText.of(HOP_HEADER)
		IngredientData.IngredientType.YEAST:
			return UiText.of(YEAST_HEADER)
		IngredientData.IngredientType.SPICE:
			return UiText.of(SPICE_HEADER)
	return UiText.of(MALT_HEADER)


## `price` is per unit after perks; `reputation` is the run's current reputation.
static func lines(ingredient : IngredientData, price : float, reputation : int) -> PackedStringArray:
	var result : PackedStringArray = [UiText.of(PRICE_FORMAT) % [price, ingredient.get_unit_string()]]
	if ingredient.min_reputation > reputation:
		result.append(UiText.of(LOCKED_FORMAT) % ingredient.min_reputation)
	if not ingredient.description.is_empty():
		result.append(UiText.of(ingredient.description))
	var stats : String = ingredient.get_stat_string()
	if not stats.is_empty():
		result.append(stats)
	return result
