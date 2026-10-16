class_name MaltPackMigration
extends RefCounted

## Save version 4 sells caramel, dark caramel, biscuit and brown malt in 100 g packs
## instead of whole kilos, so an older save's amounts of them are multiplied by ten to
## keep the same weight: in the warehouse, in saved recipes and on the brewing table.

## Caramel, brown, biscuit and dark caramel malt.
const PACKED_IDS : Array[int] = [102, 105, 106, 107]
const PACKS_PER_KILO : int = 10


static func migrate(brewery : Brewery) -> void:
	scale_items(brewery.inventory.items)
	for recipe : BrewRecipe in brewery.saved_recipes:
		scale(recipe.ingredient_amounts)
	scale(brewery.brew_preparation.selected_contents)
	scale(brewery.brew_preparation.active_recipe_target)


## Inventory.items: ingredient type -> {ingredient id -> InventoryItem}.
static func scale_items(items : Dictionary) -> void:
	for type : Variant in items:
		var by_id : Dictionary = items[type]
		for id : int in by_id:
			if PACKED_IDS.has(id):
				(by_id[id] as InventoryItem).amount *= PACKS_PER_KILO


## Multiplies the packed malts' amounts in `contents` (ingredient id -> amount) in place.
static func scale(contents : Dictionary) -> void:
	for id : int in contents:
		if PACKED_IDS.has(id):
			contents[id] = int(contents[id]) * PACKS_PER_KILO
