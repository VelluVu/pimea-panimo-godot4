class_name IngredientData
extends Resource

enum IngredientType { MALT, HOP, YEAST, SPICE }
enum UnitType { KILOGRAM, GRAM, PIECE }

@export var id : int = 0 #malts start 100, hops 200, yeasts 300, special 400 (juniper kept 212 for old recipes)
@export var name : String = ""
@export var description : String = ""
@export var base_price : int = 1
@export var unit: UnitType = UnitType.KILOGRAM
@export var type: IngredientType

@export_group("Saatavuus")
## Minimum Brewery.reputation needed to buy this ingredient — mirrors
## CustomerData.min_reputation_to_appear. Only hops and spices use a non-zero value;
## malts/yeasts stay at 0 since they're structural (required_yeast_id is a
## hard per-style requirement), so gating them would block entire style
## categories rather than just adding flavor variety as a reward.
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


func get_stat_string() -> String:
	return ""


## The translated description followed by the stats, as the shop and inventory show it.
func get_tooltip_text() -> String:
	return tr(description) + "\n" + get_stat_string()
