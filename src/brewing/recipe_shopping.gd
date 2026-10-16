class_name RecipeShopping
extends RefCounted

## What the loaded recipe still needs from the shop: whatever is on neither the brewing
## table nor the warehouse shelf, its price, and anything the reputation has not unlocked.


## Ingredient id -> amount to buy. `owned` counts the table and the warehouse together
## (Brewery.owned_ingredient_amounts()); both maps are ingredient id -> amount.
static func missing(target : Dictionary, owned : Dictionary) -> Dictionary:
	var result : Dictionary = {}
	for id : int in target:
		var short : int = int(target[id]) - int(owned.get(id, 0))
		if short > 0:
			result[id] = short
	return result


## `ingredients` is id -> IngredientData; `price_multiplier` is the shop perk.
static func cost(to_buy : Dictionary, ingredients : Dictionary, price_multiplier : float) -> float:
	var total : float = 0.0
	for id : int in to_buy:
		var data : IngredientData = ingredients.get(id)
		if data != null:
			total += data.base_price * int(to_buy[id])
	return snappedf(total * price_multiplier, 0.01)


## The first ingredient the reputation does not unlock yet, or null.
static func first_locked(to_buy : Dictionary, ingredients : Dictionary, reputation : int) -> IngredientData:
	for id : int in to_buy:
		var data : IngredientData = ingredients.get(id)
		if data != null and reputation < data.min_reputation:
			return data
	return null
