class_name QualityChallengeEventData
extends SpecialEventData

## "Bring me your best" — unlike the base bottle-request event, style
## doesn't matter here, only current_quality. Rewards skilled brewing
## (precision/hop diversity/balance) directly, since that's what drives
## current_quality up. The critic buys what is left of the best batch good enough
## (a partial batch just pays less) for a share of its counter price, and grants
## granted_perk scaled by its quality.

@export var required_min_quality: float = 1.2
## Quality at which granted_perk is given at full strength.
@export var best_quality: float = 1.6
## Strength of granted_perk at required_min_quality.
@export var min_perk_strength: float = 0.25
## Share of what the batch would bring at the counter.
@export var counter_share: float = 0.9

const REQUIREMENT_FORMAT: String = "olutta, laatu vähintään %d %%"


## The most servings any one batch on offer has: the delivery comes from one batch.
func delivery_progress(inventory: Inventory) -> Vector2i:
	var most: int = 0
	for batch: BrewBatch in inventory.brew_batches:
		if _on_offer(batch):
			most = maxi(most, batch.amount_bottles)
	return Vector2i(most, required_bottles)


func requirement_name() -> String:
	return UiText.of(REQUIREMENT_FORMAT) % roundi(required_min_quality * 100.0)


## The whole best batch on offer.
func servings_taken(brewery: Brewery) -> Dictionary:
	var batch: BrewBatch = best_batch(brewery)
	return {batch: batch.amount_bottles} if batch != null else {}


## reward_money plus counter_share of what the whole best batch would bring at the counter.
func money_on_success(brewery: Brewery) -> float:
	var batch: BrewBatch = best_batch(brewery)
	if batch == null:
		return reward_money
	return reward_money + _counter_price(brewery, batch) * batch.amount_bottles * counter_share


## granted_perk (authored at full strength) scaled by the best batch's quality.
func perk_on_success(brewery: Brewery) -> RunPerk:
	var batch: BrewBatch = best_batch(brewery)
	if granted_perk == null or batch == null:
		return null
	return granted_perk.strength_copy(perk_strength(batch.current_quality, required_min_quality, best_quality, min_perk_strength))


## The batch on offer with the highest quality, then the one worth more at the counter.
func best_batch(brewery: Brewery) -> BrewBatch:
	var best: BrewBatch = null
	var best_value: float = 0.0
	for batch: BrewBatch in brewery.inventory.brew_batches:
		if not _on_offer(batch) or batch.amount_bottles < required_bottles:
			continue
		var value: float = _counter_price(brewery, batch) * batch.amount_bottles
		if best == null or is_better(batch.current_quality, value, best.current_quality, best_value):
			best = batch
			best_value = value
	return best


## Good enough and not held back in the cellar (BrewBatch.held), like a customer sees it.
func _on_offer(batch: BrewBatch) -> bool:
	return not batch.held and batch.current_quality >= required_min_quality


func _counter_price(brewery: Brewery, batch: BrewBatch) -> float:
	return brewery.resolver.get_price_breakdown(batch.beer_style).price_per_bottle \
			* brewery.stats.multiplier(PerkStats.COUNTER_PRICE) * batch.get_aged_price_multiplier()


## min_strength at the quality bar, rising to full at best, and never past it.
static func perk_strength(quality: float, min_quality: float, best: float, min_strength: float) -> float:
	return lerpf(min_strength, 1.0, clampf(inverse_lerp(min_quality, best, quality), 0.0, 1.0))
