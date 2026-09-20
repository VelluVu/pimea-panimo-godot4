class_name YeastData
extends IngredientData


@export var attentuation_percent : int


func get_stat_string() -> String:
	return StringContainer.YEAST_STAT_STRING % attentuation_percent
