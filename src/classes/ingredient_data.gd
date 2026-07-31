class_name IngredientData
extends Resource

enum IngredientType {MALT, HOP, YEAST, SPECIAL}
enum UnitType { KILOGRAM, GRAM, PIECE }

@export var type: IngredientType
@export var id : int = 0 #malts start 100, hops 200, yeasts 300, special 400
@export var name : String = ""
@export var description : String = ""
@export var base_price : int = 1
@export var unit: UnitType = UnitType.KILOGRAM


func get_color() -> Color:
	match type:
		IngredientType.MALT:
			return Color.WHEAT
		IngredientType.HOP:
			return Color.GREEN_YELLOW
		IngredientType.YEAST:
			return Color.DARK_GOLDENROD
		_:
			return Color.BLACK


func get_unit_string() -> String:
	match unit:
		UnitType.KILOGRAM:
			return "kg"
		UnitType.GRAM:
			return "g"
		UnitType.PIECE:
			return "kpl"
		_:
			return ""
