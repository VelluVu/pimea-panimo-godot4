class_name GambleEventData
extends SpecialEventData

## A bet with a sailor: the stake is your fullest batch on offer (not held). A win pays
## the batch's counter value and you keep it; a loss takes the whole batch. Better beer
## tips the odds, from base_win_chance by quality_edge per quality point above 1.0.

@export var base_win_chance: float = 0.5
@export var quality_edge: float = 0.2
@export var min_win_chance: float = 0.35
@export var max_win_chance: float = 0.65
@export_multiline var lost_dialogue: String = ""

## Set by try_fulfill() on the copy prepared() made, for success_text().
var won: bool = false


func prepared(_brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	return duplicate()


## Settles on "Joo": the stake is on the table already.
func waits_for_delivery() -> bool:
	return false


static func win_chance(quality: float, base: float, edge: float, lowest: float, highest: float) -> float:
	return clampf(base + (quality - 1.0) * edge, lowest, highest)


## The stake shown to the bot: the whole batch, which a loss takes.
func servings_taken(brewery: Brewery) -> Dictionary:
	var batch: BrewBatch = stake(brewery.inventory)
	return {batch: batch.amount_bottles} if batch != null else {}


## Expected winnings for the playtest bot: the counter value at the win chance, plus the
## batch's own value back when it is kept (servings_taken() already counts it as lost).
func money_on_success(brewery: Brewery) -> float:
	var batch: BrewBatch = stake(brewery.inventory)
	if batch == null:
		return 0.0
	var chance: float = _chance_for(batch)
	return _counter_value(brewery, batch) * chance * 2.0


func try_fulfill(brewery: Brewery) -> bool:
	var batch: BrewBatch = stake(brewery.inventory)
	if batch == null:
		return false
	won = randf() < _chance_for(batch)
	if won:
		brewery.change_money(snappedf(_counter_value(brewery, batch), 0.1), MoneyLedger.Source.EVENTS)
	else:
		brewery.inventory.brew_batches.erase(batch)
	BrewerySignals.brewery_state_changed.emit(brewery)
	return true


func success_text() -> String:
	return success_dialogue if won else lost_dialogue


func counts_as_success() -> bool:
	return won


## The fullest batch on offer.
func stake(inventory: Inventory) -> BrewBatch:
	var best: BrewBatch = null
	for batch: BrewBatch in inventory.brew_batches:
		if not batch.held and batch.amount_bottles > 0 and (best == null or batch.amount_bottles > best.amount_bottles):
			best = batch
	return best


func get_weight(brewery: Brewery) -> float:
	return super(brewery) if stake(brewery.inventory) != null else 0.0


func _chance_for(batch: BrewBatch) -> float:
	return win_chance(batch.current_quality, base_win_chance, quality_edge, min_win_chance, max_win_chance)


func _counter_value(brewery: Brewery, batch: BrewBatch) -> float:
	return brewery.resolver.get_price_breakdown(batch.beer_style).price_per_bottle * batch.get_aged_price_multiplier() * batch.amount_bottles
