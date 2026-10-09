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
## Authored at full strength; kept out of the perks folder so it never shows on a level-up card.
@export var granted_perk: RunPerk

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


func try_fulfill(brewery: Brewery) -> bool:
	var best_batch: BrewBatch = null
	var best_value: float = 0.0

	for batch: BrewBatch in brewery.inventory.brew_batches:
		if not _on_offer(batch) or batch.amount_bottles < required_bottles:
			continue
		var value: float = _counter_price(brewery, batch) * batch.amount_bottles
		if best_batch == null or is_better(batch.current_quality, value, best_batch.current_quality, best_value):
			best_batch = batch
			best_value = value

	if best_batch == null:
		return false

	brewery.inventory.brew_batches.erase(best_batch)
	brewery.change_money(snappedf(best_value * counter_share, 0.1), MoneyLedger.Source.EVENTS)
	_apply_rewards(brewery)
	if granted_perk != null:
		brewery.apply_perk(granted_perk.strength_copy(perk_strength(best_batch.current_quality, required_min_quality, best_quality, min_perk_strength)))
	return true


## Good enough and not held back in the cellar (BrewBatch.held), like a customer sees it.
func _on_offer(batch: BrewBatch) -> bool:
	return not batch.held and batch.current_quality >= required_min_quality


func _counter_price(brewery: Brewery, batch: BrewBatch) -> float:
	return brewery.resolver.get_price_breakdown(batch.beer_style).price_per_bottle \
			* brewery.stats.multiplier(PerkStats.COUNTER_PRICE) * batch.get_aged_price_multiplier()


## min_strength at the quality bar, rising to full at best, and never past it.
static func perk_strength(quality: float, min_quality: float, best: float, min_strength: float) -> float:
	return lerpf(min_strength, 1.0, clampf(inverse_lerp(min_quality, best, quality), 0.0, 1.0))
