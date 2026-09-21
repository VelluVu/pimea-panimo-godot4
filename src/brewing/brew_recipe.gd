class_name BrewRecipe
extends Resource


@export var recipe_name: String = ""
@export var beer_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA
@export var ingredient_amounts: Dictionary = {} # Avain: int (Ingredient ID) -> Arvo: int (Määrä)
@export var is_default: bool = false


## Whether the inventory holds every ingredient in the amounts this recipe needs.
func is_covered_by(inventory : Inventory) -> bool:
	for ingredient_id : int in ingredient_amounts:
		var item : InventoryItem = inventory.get_item_by_id(ingredient_id)
		var owned : int = item.amount if item else 0
		if owned < ingredient_amounts[ingredient_id]:
			return false
	return true
