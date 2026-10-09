class_name IngredientDonationEventData
extends SpecialEventData

## Asks for raw ingredients out of the warehouse instead of finished beer —
## ties the special event loop into the shopping/inventory side of the game
## rather than only the brewing/selling side.
## With rolls_ingredient the ingredient is rolled from rolled_type each visit
## (prepared()); intro_dialogue then takes its name and the amount (%s, %d).
## The buyer pays the shop price plus price_markup, and grants granted_perk.

@export var required_ingredient_id: int = 100
@export var required_ingredient_amount: int = 5
@export var rolls_ingredient: bool = false
@export var rolled_type: IngredientData.IngredientType = IngredientData.IngredientType.MALT
## Paid on top of what the ingredient costs the player in the shop.
@export var price_markup: float = 0.0
## Given on each success; kept out of the perks folder so it never shows on a level-up card.
@export var granted_perk: RunPerk


func prepared(brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	if not rolls_ingredient:
		return self
	var ids: Array[int] = ids_of_type(IngredientDatabase.database.values(), rolled_type, brewery.reputation)
	if ids.is_empty():
		return self
	var rolled := duplicate() as IngredientDonationEventData
	rolled.required_ingredient_id = ids.pick_random()
	return rolled


func intro_text() -> String:
	if not rolls_ingredient:
		return super()
	return tr(intro_dialogue) % [requirement_name(), required_ingredient_amount]


## Ingredients of `type` the player can buy at `reputation`.
static func ids_of_type(ingredients: Array, type: IngredientData.IngredientType, reputation: int) -> Array[int]:
	var ids: Array[int] = []
	for ingredient: IngredientData in ingredients:
		if ingredient.type == type and reputation >= ingredient.min_reputation:
			ids.append(ingredient.id)
	return ids


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
	if price_markup > 0.0:
		brewery.change_money(snappedf(_shop_value(brewery) * (1.0 + price_markup), 0.1), MoneyLedger.Source.EVENTS)
	_apply_rewards(brewery)
	if granted_perk != null:
		brewery.apply_perk(granted_perk)
	return true


## What the asked amount costs the player in the shop right now.
func _shop_value(brewery: Brewery) -> float:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(required_ingredient_id)
	if ingredient == null:
		return 0.0
	return ingredient.base_price * required_ingredient_amount * brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)
