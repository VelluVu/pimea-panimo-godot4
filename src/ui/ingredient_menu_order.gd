class_name IngredientMenuOrder
extends RefCounted

## An ingredient dropdown's order: unlocked first as given, then locked ones nearest to
## unlocking. `owned` keeps an ingredient usable after reputation drops.


static func order(ingredients : Array[IngredientData], reputation : int, owned : Dictionary = {}) -> Array[IngredientData]:
	var unlocked : Array[IngredientData] = []
	var locked : Array[IngredientData] = []
	for ingredient : IngredientData in ingredients:
		if is_locked(ingredient, reputation, owned):
			locked.append(ingredient)
		else:
			unlocked.append(ingredient)
	locked.sort_custom(func(a : IngredientData, b : IngredientData) -> bool:
		return a.min_reputation < b.min_reputation or (a.min_reputation == b.min_reputation and a.id < b.id))
	return unlocked + locked


static func is_locked(ingredient : IngredientData, reputation : int, owned : Dictionary = {}) -> bool:
	return is_buy_locked(ingredient, reputation) and owned.get(ingredient.id, 0) <= 0


static func is_buy_locked(ingredient : IngredientData, reputation : int) -> bool:
	return reputation < ingredient.min_reputation
