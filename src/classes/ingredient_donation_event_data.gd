class_name IngredientDonationEventData
extends SpecialEventData

## Asks for raw ingredients out of the warehouse instead of finished beer —
## ties the special event loop into the shopping/inventory side of the game
## rather than only the brewing/selling side.

@export var required_ingredient_id: int = 100
@export var required_ingredient_amount: int = 5


func try_fulfill(brewery: Brewery) -> bool:
	var item: InventoryItem = brewery.inventory.get_item_by_id(required_ingredient_id)
	if item == null or item.amount < required_ingredient_amount:
		return false

	brewery.inventory.withdraw_item_by_id(required_ingredient_id, required_ingredient_amount)
	_apply_rewards(brewery)
	return true
