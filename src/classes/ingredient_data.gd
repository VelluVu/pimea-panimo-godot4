class_name IngredientData
extends Resource

enum IngredientType { MALT, HOP, YEAST }
enum UnitType { KILOGRAM, GRAM, PIECE }

@export var id : int = 0 #malts start 100, hops 200, yeasts 300, special 400
@export var name : String = ""
@export var description : String = ""
@export var base_price : int = 1
@export var unit: UnitType = UnitType.KILOGRAM
@export var type: IngredientType


func get_color() -> Color:
	if type == IngredientType.MALT: return Color.WHEAT
	if type == IngredientType.HOP: return Color.GREEN_YELLOW
	if type == IngredientType.YEAST: return Color.DARK_GOLDENROD
	return Color.BLACK


func get_unit_string() -> String:
	if type == IngredientType.MALT: return StringContainer.KG
	if type == IngredientType.HOP: return StringContainer.G
	if type == IngredientType.YEAST: return StringContainer.KPL
	return StringContainer.KPL


func get_stat_string() -> String:
	return ""
