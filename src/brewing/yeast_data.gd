class_name YeastData
extends IngredientData


@export var attentuation_percent : int
## Stops fermenting before any alcohol forms: a brew that fails its style with this
## yeast still comes out alcohol-free (see BrewResolver.ALCOHOL_FREE_FALLBACK_ABV).
@export var alcohol_free : bool = false


func get_stat_string() -> String:
	return tr(StringContainer.YEAST_STAT_STRING) % attentuation_percent
