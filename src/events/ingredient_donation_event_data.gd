class_name IngredientDonationEventData
extends SpecialEventData

## Asks for raw ingredients out of the warehouse instead of finished beer —
## ties the special event loop into the shopping/inventory side of the game
## rather than only the brewing/selling side.

@export var required_ingredient_id: int = 100
@export var required_ingredient_amount: int = 5


func delivery_progress(inventory: Inventory) -> Vector2i:
	var item: InventoryItem = inventory.get_item_by_id(required_ingredient_id)
	return Vector2i(item.amount if item != null else 0, required_ingredient_amount)


func requirement_name() -> String:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(required_ingredient_id)
	return UiText.of(ingredient.name) if ingredient != null else ""


func try_fulfill(brewery: Brewery) -> bool:
	var item: InventoryItem = brewery.inventory.get_item_by_id(required_ingredient_id)
	if item == null or item.amount < required_ingredient_amount:
		return false

	brewery.inventory.withdraw_item_by_id(required_ingredient_id, required_ingredient_amount)
	_apply_rewards(brewery)
	return true
