class_name YeastData
extends IngredientData


@export var attentuation_percent : int
## The beer family this yeast makes ("lager", "ale"), shown on undiscovered styles.
@export var family_name : String = ""


func get_stat_string() -> String:
	return tr(StringContainer.YEAST_STAT_STRING) % attentuation_percent
