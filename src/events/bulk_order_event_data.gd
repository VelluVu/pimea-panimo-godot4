class_name BulkOrderEventData
extends SpecialEventData

## A big order (the dance hall): required_bottles servings in all of any accepted_styles,
## taken from as many batches on offer (not held) as it needs, fullest first. Pays
## pub_share of the pub price per serving on top of reward_money.

const STYLE_SEPARATOR: String = " tai "

@export var accepted_styles: Array[BeerStyle.Style] = []
@export var pub_share: float = 0.8


func delivery_progress(inventory: Inventory) -> Vector2i:
	var have: int = 0
	for batch: BrewBatch in offered_batches(inventory, accepted_styles):
		have += batch.amount_bottles
	return Vector2i(have, required_bottles)


func requirement_name() -> String:
	var names: PackedStringArray = []
	for style: BeerStyle.Style in accepted_styles:
		names.append(BeerStyle.get_style_string_from_style(style))
	return tr(STYLE_SEPARATOR).join(names)


## The whole order from the fullest batches first, or nothing until it is all there.
func servings_taken(brewery: Brewery) -> Dictionary:
	return take_from(offered_batches(brewery.inventory, accepted_styles), required_bottles)


## BrewBatch -> servings covering `amount` from `batches` in order; empty when they fall short.
static func take_from(batches: Array[BrewBatch], amount: int) -> Dictionary:
	var taken: Dictionary = {}
	var left: int = amount
	for batch: BrewBatch in batches:
		if left <= 0:
			break
		var servings: int = mini(left, batch.amount_bottles)
		taken[batch] = servings
		left -= servings
	return taken if left <= 0 else {}


func money_on_success(brewery: Brewery) -> float:
	var money: float = reward_money
	var taken: Dictionary = servings_taken(brewery)
	for batch: BrewBatch in taken:
		money += brewery.resolver.get_price_breakdown(batch.beer_style).price_per_bottle * taken[batch] * pub_share
	return money


## Batches of `styles` on offer, fullest first.
static func offered_batches(inventory: Inventory, styles: Array[BeerStyle.Style]) -> Array[BrewBatch]:
	var found: Array[BrewBatch] = []
	for batch: BrewBatch in inventory.brew_batches:
		if not batch.held and batch.amount_bottles > 0 and batch.beer_style.style in styles:
			found.append(batch)
	found.sort_custom(func(a: BrewBatch, b: BrewBatch) -> bool: return a.amount_bottles > b.amount_bottles)
	return found
