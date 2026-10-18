class_name MaltPackMigration
extends RefCounted

## Malts that moved from whole kilos to smaller packs: an older save's amounts are scaled to
## the same weight in the warehouse, recipes and table. Save version 4: specialty malts in
## 100 g, 5: dual-use malts in 500 g, 6: Münchenin in 100 g.

## Caramel, brown, biscuit and dark caramel malt.
const PACKED_IDS : Array[int] = [102, 105, 106, 107]
const PACKS_PER_KILO : int = 10
## Wheat, Münchenin, Vienna and rye malt.
const HALF_KILO_IDS : Array[int] = [103, 104, 109, 110]
const HALF_KILO_PACKS : int = 2
## Münchenin, from 500 g to 100 g packs.
const SMALL_PACK_IDS : Array[int] = [104]
const SMALL_PACKS_PER_HALF_KILO : int = 5


static func migrate(brewery : Brewery, ids : Array[int] = PACKED_IDS, factor : int = PACKS_PER_KILO) -> void:
	scale_items(brewery.inventory.items, ids, factor)
	for recipe : BrewRecipe in brewery.saved_recipes:
		scale(recipe.ingredient_amounts, ids, factor)
	scale(brewery.brew_preparation.selected_contents, ids, factor)
	scale(brewery.brew_preparation.active_recipe_target, ids, factor)


## Inventory.items: ingredient type -> {ingredient id -> InventoryItem}.
static func scale_items(items : Dictionary, ids : Array[int] = PACKED_IDS, factor : int = PACKS_PER_KILO) -> void:
	for type : Variant in items:
		var by_id : Dictionary = items[type]
		for id : int in by_id:
			if ids.has(id):
				(by_id[id] as InventoryItem).amount *= factor


## Multiplies the `ids` amounts in `contents` (ingredient id -> amount) in place.
static func scale(contents : Dictionary, ids : Array[int] = PACKED_IDS, factor : int = PACKS_PER_KILO) -> void:
	for id : int in contents:
		if ids.has(id):
			contents[id] = int(contents[id]) * factor
