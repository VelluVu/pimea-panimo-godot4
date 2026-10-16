class_name IngredientSource
extends RefCounted

## Where brewing logic reads ingredients from: IngredientDatabase by default, or an
## injected table, since the test runner cannot reach the autoload.

var _injected_table : Dictionary = {}
var _is_injected : bool = false


## Reads from `ingredient_table` (id -> IngredientData) instead of IngredientDatabase.
func inject(ingredient_table : Dictionary) -> void:
	_injected_table = ingredient_table
	_is_injected = true


func table() -> Dictionary:
	return _injected_table if _is_injected else IngredientDatabase.database


## What a combo (id -> amount) costs at base prices.
func combo_cost(combo : Dictionary) -> float:
	var cost : float = 0.0
	for id : int in combo:
		var data : IngredientData = table().get(id)
		if data != null:
			cost += data.base_price * combo[id]
	return cost

