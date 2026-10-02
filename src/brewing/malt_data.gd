class_name MaltData
extends IngredientData


@export var ebc : int


func get_stat_string() -> String:
	return tr(StringContainer.MALT_STAT_STRING) % ebc
