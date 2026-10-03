class_name IngredientMenuOrder
extends RefCounted

## The order of an ingredient dropdown: unlocked items first, in the given order,
## then locked ones nearest to unlocking, so the usable part of a long list is on top.


static func order(ingredients : Array[IngredientData], reputation : int) -> Array[IngredientData]:
	var unlocked : Array[IngredientData] = []
	var locked : Array[IngredientData] = []
	for ingredient : IngredientData in ingredients:
		if is_locked(ingredient, reputation):
			locked.append(ingredient)
		else:
			unlocked.append(ingredient)
	locked.sort_custom(func(a : IngredientData, b : IngredientData) -> bool:
		return a.min_reputation < b.min_reputation or (a.min_reputation == b.min_reputation and a.id < b.id))
	return unlocked + locked


static func is_locked(ingredient : IngredientData, reputation : int) -> bool:
	return reputation < ingredient.min_reputation
