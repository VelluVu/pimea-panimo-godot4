class_name IngredientSource
extends RefCounted

## Where brewing logic reads ingredients from: IngredientDatabase by default, or an
## injected table, since the test runner cannot reach the autoload.

var _injected_table : Dictionary = {}
var _injected_ids : Array[int] = []
var _is_injected : bool = false


## Reads from `table` (id -> IngredientData) instead of IngredientDatabase. Ids are
## iterated in ascending order, like IngredientDatabase.sorted_ids.
func inject(table : Dictionary) -> void:
	_injected_table = table
	_injected_ids.clear()
	for id : int in table.keys():
		_injected_ids.append(id)
	_injected_ids.sort()
	_is_injected = true


func table() -> Dictionary:
	return _injected_table if _is_injected else IngredientDatabase.database


func ids() -> Array[int]:
	return _injected_ids if _is_injected else IngredientDatabase.sorted_ids


func all_malts() -> Array[MaltData]:
	var malts : Array[MaltData] = []
	malts.assign(_all().filter(func(data : IngredientData) -> bool: return data is MaltData))
	return malts


func all_hops() -> Array[HopData]:
	var hops : Array[HopData] = []
	hops.assign(_all().filter(func(data : IngredientData) -> bool: return data is HopData))
	return hops


func find_malt_combo(beer_style : BeerStyle) -> Dictionary:
	return RecipeSearch.find_malt_combo(all_malts(), beer_style.min_ebc, beer_style.max_ebc, beer_style.min_malt_weight, beer_style.required_malt_id)


## What a combo (id -> amount) costs at base prices.
func combo_cost(combo : Dictionary) -> int:
	var cost : int = 0
	for id : int in combo:
		cost += table()[id].base_price * combo[id]
	return cost


func _all() -> Array:
	return ids().map(func(id : int) -> IngredientData: return table()[id])
