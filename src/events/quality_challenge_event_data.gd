class_name QualityChallengeEventData
extends SpecialEventData

## "Bring me your best" — unlike the base bottle-request event, style
## doesn't matter here, only current_quality. Rewards skilled brewing
## (precision/hop diversity/balance) directly, since that's what drives
## current_quality up. The critic buys the whole best batch good enough, for a
## share of its counter price, and grants granted_perk scaled by its quality.

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

	var counter_price: float = brewery.resolver.get_price_breakdown(best_batch.beer_style).price_per_bottle \
			* brewery.stats.multiplier(PerkStats.COUNTER_PRICE) * best_batch.get_aged_price_multiplier()
	brewery.inventory.brew_batches.erase(best_batch)
	brewery.change_money(snappedf(counter_price * best_batch.amount_bottles * counter_share, 0.1), MoneyLedger.Source.EVENTS)
	_apply_rewards(brewery)
	if granted_perk != null:
		brewery.apply_perk(granted_perk.strength_copy(perk_strength(best_batch.current_quality, required_min_quality, best_quality, min_perk_strength)))
	return true


## min_strength at the quality bar, rising to full at best, and never past it.
static func perk_strength(quality: float, min_quality: float, best: float, min_strength: float) -> float:
	return lerpf(min_strength, 1.0, clampf(inverse_lerp(min_quality, best, quality), 0.0, 1.0))
