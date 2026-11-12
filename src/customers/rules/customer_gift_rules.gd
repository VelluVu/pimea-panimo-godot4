class_name CustomerGiftRules
extends RefCounted

## A customer with a gift (Maajussi's barley) leaves it after a visit where he bought
## something, at his CustomerData.gift_chance.


## `roll` is randf(), passed in for tests.
static func leaves_gift(ingredient_id: int, amount: int, chance: float, bottles_sold: int, roll: float) -> bool:
	if ingredient_id < 0 or amount <= 0 or bottles_sold <= 0:
		return false
	return roll < chance
