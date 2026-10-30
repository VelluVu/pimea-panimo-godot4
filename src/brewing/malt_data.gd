class_name MaltData
extends IngredientData


## Real maltster colour; the beer's colour comes from BrewFormulas (Morey).
@export var ebc : int
## Share of sugar's extract the malt gives, see BrewFormulas.gravity_points().
@export var extract : float = 0.8
## Sugar dissolves fully instead of being mashed (candi syrup).
@export var is_sugar : bool = false
## Grams in one unit: 1000 for malts sold by the kilo, 100 for dark roast malts used in
## small amounts.
@export var pack_grams : int = 1000

const PACK_FORMAT : String = "%d g"


func kg(amount : int) -> float:
	return amount * pack_grams / 1000.0


## Packs show as kilograms with one decimal ("0.3"), whole kilos as they are.
func amount_text(amount : int) -> String:
	if pack_grams == 1000:
		return str(amount)
	return NumberText.decimal(kg(amount), 1)


func get_pack_string() -> String:
	if pack_grams == 1000:
		return get_unit_string()
	return PACK_FORMAT % pack_grams


func get_stat_string() -> String:
	return tr(StringContainer.MALT_STAT_STRING) % ebc
