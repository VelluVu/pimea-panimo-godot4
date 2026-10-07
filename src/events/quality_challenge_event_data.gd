class_name QualityChallengeEventData
extends SpecialEventData

## "Bring me your best" — unlike the base bottle-request event, style
## doesn't matter here, only current_quality. Rewards skilled brewing
## (precision/hop diversity/balance) directly, since that's what drives
## current_quality up.

@export var required_min_quality: float = 1.2

const REQUIREMENT_FORMAT: String = "olutta, laatu vähintään %d %%"


## The most bottles any one batch good enough has: the delivery comes from one batch.
func delivery_progress(inventory: Inventory) -> Vector2i:
	var most: int = 0
	for batch: BrewBatch in inventory.brew_batches:
		if batch.current_quality >= required_min_quality:
			most = maxi(most, batch.amount_bottles)
	return Vector2i(most, required_bottles)


func requirement_name() -> String:
	return UiText.of(REQUIREMENT_FORMAT) % roundi(required_min_quality * 100.0)


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
