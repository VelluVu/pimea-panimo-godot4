class_name QualityChallengeEventData
extends SpecialEventData

## "Bring me your best" — unlike the base bottle-request event, style
## doesn't matter here, only current_quality. Rewards skilled brewing
## (precision/hop diversity/balance) directly, since that's what drives
## current_quality up.

@export var required_min_quality: float = 1.2


func try_fulfill(brewery: Brewery) -> bool:
	var best_batch: BrewBatch = null

	for batch: BrewBatch in brewery.inventory.brew_batches:
		if batch.current_quality < required_min_quality or batch.amount_bottles < required_bottles:
			continue
		if best_batch == null or batch.current_quality > best_batch.current_quality:
			best_batch = batch

	if best_batch == null:
		return false

	best_batch.amount_bottles -= required_bottles
	_apply_rewards(brewery)

	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)

	return true
