class_name RecipeFill
extends RefCounted

## "Täytä resepti": what the warehouse shelf adds to the brewing table to complete the loaded
## recipe. All or nothing, so the button and the fill always agree.


## Ingredient id -> amount to move from the shelf. Empty when nothing is missing or the shelf
## is short of any of it. `owned` counts the table and the shelf together
## (Brewery.owned_ingredient_amounts()); all maps are ingredient id -> amount.
static func from_stock(target : Dictionary, on_table : Dictionary, owned : Dictionary) -> Dictionary:
	var result : Dictionary = {}
	for id : int in target:
		var missing : int = int(target[id]) - int(on_table.get(id, 0))
		if missing <= 0:
			continue
		if int(owned.get(id, 0)) < int(target[id]):
			return {}
		result[id] = missing
	return result
