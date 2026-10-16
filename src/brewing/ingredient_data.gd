class_name IngredientData
extends Resource

enum IngredientType { MALT, HOP, YEAST, SPICE }
enum UnitType { KILOGRAM, GRAM, PIECE }

@export var id : int = 0 #malts start 100, hops 200, yeasts 300, special 400 (juniper kept 212 for old recipes)
@export var name : String = ""
## The name in the partitive ("5 kiloa savumallasta"); empty falls back to name.
@export var name_partitive : String = ""
@export var description : String = ""
@export var base_price : int = 1
@export var unit: UnitType = UnitType.KILOGRAM
@export var type: IngredientType

@export_group("Saatavuus")
## Reputation needed to buy this. Only hops and spices use it: gating malts or yeasts
## would lock whole styles out instead of adding variety.
@export var min_reputation: int = 0


func get_color() -> Color:
	return get_color_for_type(type)


static func get_color_for_type(ingredient_type : IngredientType) -> Color:
	if ingredient_type == IngredientType.MALT: return Color.WHEAT
	if ingredient_type == IngredientType.HOP: return Color.GREEN_YELLOW
	if ingredient_type == IngredientType.YEAST: return Color.DARK_GOLDENROD
	if ingredient_type == IngredientType.SPICE: return Color.CADET_BLUE
	return Color.BLACK


func get_unit_string() -> String:
	if type == IngredientType.MALT: return StringContainer.KG
	if type == IngredientType.HOP: return StringContainer.G
	if type == IngredientType.YEAST: return tr(StringContainer.KPL)
	return tr(StringContainer.KPL)


## The number shown for `amount` units, in get_unit_string() units.
func amount_text(amount : int) -> String:
	return str(amount)


## What one bought unit is, for prices ("€ / kg").
func get_pack_string() -> String:
	return get_unit_string()


func get_stat_string() -> String:
	return ""


## The translated description followed by the stats, as the shop and inventory show it.
func get_tooltip_text() -> String:
	return tr(description) + "\n" + get_stat_string()
