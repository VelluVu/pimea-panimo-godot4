class_name ReputationUnlockTracker
extends RefCounted

## Finds ingredients that a reputation increase just unlocked. Only a genuine
## increase counts: an LVV raid's reputation penalty must never announce a
## "newly unlocked" ingredient that was already available before the drop.

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
