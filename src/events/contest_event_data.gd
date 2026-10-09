class_name ContestEventData
extends SpecialEventData

## A beer contest: send required_bottles servings of your best batch on offer (not held).
## Its quality plus a little luck decides the outcome: a win pays win_money and
## win_reputation, a place place_reputation, and anything less nothing.

enum Outcome { NONE, LOST, PLACED, WON }

const REQUIREMENT_TEXT: String = "parasta olutta"

@export var win_quality: float = 1.4
@export var place_quality: float = 1.15
## Luck on top of the quality, from -luck to +luck.
@export var luck: float = 0.15
@export var win_money: int = 50
@export var win_reputation: int = 25
@export var place_reputation: int = 10
@export_multiline var placed_dialogue: String = ""
@export_multiline var lost_dialogue: String = ""

## Set by try_fulfill() on the copy prepared() made, for success_text().
var outcome: Outcome = Outcome.NONE


func prepared(_brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	return duplicate()


## What a judged score earns: WON, PLACED or LOST.
static func judge(score: float, win_at: float, place_at: float) -> Outcome:
	if score >= win_at:
		return Outcome.WON
	if score >= place_at:
		return Outcome.PLACED
	return Outcome.LOST


func servings_taken(brewery: Brewery) -> Dictionary:
	var batch: BrewBatch = best_batch(brewery.inventory)
	return {batch: required_bottles} if batch != null else {}


func delivery_progress(inventory: Inventory) -> Vector2i:
	var batch: BrewBatch = best_batch(inventory)
	return Vector2i(batch.amount_bottles if batch != null else 0, required_bottles)


func requirement_name() -> String:
	return UiText.of(REQUIREMENT_TEXT)


## The expected prize, for the playtest bot: the win at the batch's chance of winning.
func money_on_success(brewery: Brewery) -> float:
	var batch: BrewBatch = best_batch(brewery.inventory)
	if batch == null:
		return 0.0
	return win_money * clampf((batch.current_quality + luck - win_quality) / (2.0 * luck), 0.0, 1.0)


func try_fulfill(brewery: Brewery) -> bool:
	var taken: Dictionary = servings_taken(brewery)
	if taken.is_empty():
		return false
	var batch: BrewBatch = taken.keys()[0]
	outcome = judge(batch.current_quality + randf_range(-luck, luck), win_quality, place_quality)
	batch.amount_bottles -= required_bottles
	if batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(batch)
	match outcome:
		Outcome.WON:
			brewery.change_money(win_money, MoneyLedger.Source.EVENTS)
			brewery.change_reputation(win_reputation, ReputationRules.Source.EVENTS)
		Outcome.PLACED:
			brewery.change_reputation(place_reputation, ReputationRules.Source.EVENTS)
	return true


func success_text() -> String:
	match outcome:
		Outcome.PLACED:
			return placed_dialogue
		Outcome.LOST:
			return lost_dialogue
	return success_dialogue


## The batch on offer with the highest quality, then the most servings.
func best_batch(inventory: Inventory) -> BrewBatch:
	var best: BrewBatch = null
	for batch: BrewBatch in inventory.brew_batches:
		if batch.held or batch.amount_bottles < required_bottles:
			continue
		if best == null or is_better(batch.current_quality, batch.amount_bottles, best.current_quality, best.amount_bottles):
			best = batch
	return best

