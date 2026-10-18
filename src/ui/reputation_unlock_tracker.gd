class_name ReputationUnlockTracker
extends RefCounted

## Ingredients a reputation rise just unlocked; a raid's drop never announces old ones.

var _last_reputation: int


func _init(starting_reputation: int) -> void:
	_last_reputation = starting_reputation


## Records the new reputation and returns the ingredients it newly unlocked.
func update(new_reputation: int) -> Array[IngredientData]:
	var unlocked: Array[IngredientData] = []
	if new_reputation > _last_reputation:
		for ingredient: IngredientData in IngredientDatabase.database.values():
			if ingredient.min_reputation > _last_reputation and ingredient.min_reputation <= new_reputation:
				unlocked.append(ingredient)
	_last_reputation = new_reputation
	return unlocked
