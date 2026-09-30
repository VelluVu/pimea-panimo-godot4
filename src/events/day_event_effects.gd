class_name DayEventEffects
extends RefCounted

## The one-off stock hit of an unfortunate day event. Each function returns how much
## was actually lost, which can be less than rolled when stock runs short.


static func apply(inventory: Inventory, event: DayEventData) -> int:
	match event.effect_type:
		DayEventData.EffectType.INGREDIENT_LOSS:
			return remove_ingredients(inventory, event.effect_ingredient_type, event.get_effect_amount())
		DayEventData.EffectType.BOTTLE_SPOILAGE:
			return spoil_bottles(inventory, event.get_effect_amount())
	return 0


## Takes `amount` units from one ingredient type, emptying items in bucket order.
static func remove_ingredients(inventory: Inventory, type: IngredientData.IngredientType, amount: int) -> int:
	var bucket: Dictionary = inventory.items.get(type, {})
	var removed: int = 0
	for id: int in bucket.keys():
		if removed >= amount:
			break
		var item: InventoryItem = bucket[id]
		removed += inventory.withdraw_item(item.ingredient_data, mini(item.amount, amount - removed))
	return removed


## Spoils up to `amount` bottles from one random batch; an emptied batch is dropped.
static func spoil_bottles(inventory: Inventory, amount: int) -> int:
	if inventory.brew_batches.is_empty():
		return 0
	var batch: BrewBatch = inventory.brew_batches.pick_random()
	var removed: int = mini(batch.amount_bottles, amount)
	batch.amount_bottles -= removed
	if batch.amount_bottles <= 0:
		inventory.brew_batches.erase(batch)
	return removed
