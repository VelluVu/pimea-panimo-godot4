class_name RepairOfferEventData
extends PerkOfferEventData

## A repair the player can skip at a price: pay offer_cost on "Joo", or let it pass and,
## with damage_chance, a random batch loses damage_quality right away.

@export var damage_chance: float = 0.6
@export var damage_quality: float = 0.15
@export_multiline var damage_dialogue: String = ""

## Set by on_rejected() on the copy prepared() made, for reject_text().
var damaged: bool = false


## Only worth a call when something could break.
func get_weight(brewery: Brewery) -> float:
	return super(brewery) if not brewery.inventory.brew_batches.is_empty() else 0.0


func on_rejected(brewery: Brewery) -> void:
	if brewery.inventory.brew_batches.is_empty() or randf() >= damage_chance:
		return
	var batch: BrewBatch = brewery.inventory.brew_batches.pick_random()
	batch.current_quality = maxf(0.1, batch.current_quality - damage_quality)
	batch.original_quality = maxf(0.1, batch.original_quality - damage_quality)
	damaged = true
	BrewerySignals.brewery_state_changed.emit(brewery)


func reject_text() -> String:
	return damage_dialogue if damaged else reject_dialogue
