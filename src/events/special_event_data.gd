class_name SpecialEventData
extends Resource

## Base special event: "bring N servings of style X". Subclasses override try_fulfill() and
## reuse the rest. Goods wait after "Joo" (delivery_seconds); a payment settles at once
## (waits_for_delivery()).


@export var event_caller_name: String = "Kaljabisnesmies"
@export var intro_dialogue: String = "Nyt pitäs saada reippaasti kaljaa kaikille, eli bulkkia vähintään 20 annosta!"
@export var success_dialogue: String = "Nyt bileet pystyyn!"
@export var fail_dialogue: String = "Eikö täältä räkälästä saa ees bulkkii kaikille?"
@export var reject_dialogue : String = "Päätit olla tarttumatta tarjoukseen. Jatketaan pimeää bisnestä."
@export var timeout_seconds: float = 10.0
## After "Joo": seconds to get the goods in before the request fails.
@export var delivery_seconds: float = 30.0

@export_group("Vaatimus")
@export var required_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var required_bottles: int = 20

@export_group("Palkkiot")
@export var reward_money: int = 70
@export var reward_reputation: int = 10
@export var reward_risk: int = 5
@export var clears_risk: bool = false
## Reputation lost when "Joo" was said but the goods never came (the critic).
@export var fail_reputation_penalty: int = 0
## Given on each success. Event perks live outside the perks folder, off level-up cards.
@export var granted_perk: RunPerk
## Likelier as LVV risk climbs (risk_weight()), on events that lower risk.
@export var weighs_by_risk: bool = false

## How many times as likely a weighs_by_risk event is at the raid threshold as at risk 0.
const MAX_RISK_WEIGHT_MULTIPLIER: float = 2.0


## Relative odds of this event being rolled: 1.0, or risk_weight() for weighs_by_risk.
## Subclasses bias it further (a favour drops to 0 when it cannot be paid).
func get_weight(brewery: Brewery) -> float:
	return risk_weight(brewery) if weighs_by_risk else 1.0


## 1.0 at no risk, rising to MAX_RISK_WEIGHT_MULTIPLIER at the raid threshold.
static func risk_weight(brewery: Brewery) -> float:
	return 1.0 + risk_fraction(brewery) * (MAX_RISK_WEIGHT_MULTIPLIER - 1.0)


## LVV risk as a share of the effective raid threshold, 0 to 1.
static func risk_fraction(brewery: Brewery) -> float:
	var threshold: int = brewery.get_effective_raid_threshold()
	if threshold <= 0:
		return 1.0
	return clampf(float(brewery.risk) / float(threshold), 0.0, 1.0)


## The event as it shows up this time. An event that rolls its request returns a
## rolled copy (WeddingOrderEventData); `bars` are the shipping contacts.
func prepared(_brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	return self


## The opening line, translated, with its named numbers filled in (intro_values()).
func intro_text() -> String:
	return tr(intro_dialogue).format(intro_values())


## Numbers an intro line quotes by name ({servings}, {risk}), from the event's own data, so
## a line never quotes a stale price.
func intro_values() -> Dictionary:
	return {"servings": required_bottles, "money": reward_money, "risk": absi(reward_risk),
			"fail_reputation": fail_reputation_penalty}


## What is still missing while the goods are on their way, translated.
func delivery_text(inventory: Inventory) -> String:
	var progress: Vector2i = delivery_progress(inventory)
	return SpecialEventText.delivery(requirement_name(), progress.x, progress.y)


## False for a request that settles on "Joo" (a payment), see the subclasses.
func waits_for_delivery() -> bool:
	return true


func can_fulfill(brewery: Brewery) -> bool:
	var progress: Vector2i = delivery_progress(brewery.inventory)
	return progress.x >= progress.y


## How much of the requirement is in stock (x) out of what is asked (y).
func delivery_progress(inventory: Inventory) -> Vector2i:
	var batch := _find_batch_by_style(inventory, required_style)
	return Vector2i(batch.amount_bottles if batch != null else 0, required_bottles)


## What is asked for, as shown while it is being delivered (translated).
func requirement_name() -> String:
	return BeerStyle.get_style_string_from_style(required_style)


## Settles the event if its requirement is met, else changes nothing. Subclasses override
## it for other requirements and call _settle().
func try_fulfill(brewery: Brewery) -> bool:
	var taken: Dictionary = servings_taken(brewery)
	if taken.is_empty():
		return false
	_settle(brewery, taken)
	return true


## What a success would pay now; the bot reads it too, so it matches _settle().
func money_on_success(_brewery: Brewery) -> float:
	return reward_money


## The batches a success would take, BrewBatch -> servings; empty when the goods are not
## there or the request is not beer.
func servings_taken(brewery: Brewery) -> Dictionary:
	var batch: BrewBatch = _find_batch_by_style(brewery.inventory, required_style)
	if batch == null or batch.amount_bottles < required_bottles:
		return {}
	return {batch: required_bottles}


## Called when the player lets the offer pass (the window times out); most events shrug.
func on_rejected(_brewery: Brewery) -> void:
	pass


## An accepted request that was never fulfilled.
func on_failed(brewery: Brewery) -> void:
	if fail_reputation_penalty != 0:
		brewery.change_reputation(-fail_reputation_penalty, ReputationRules.Source.EVENTS)


## The reply after a success; events whose outcome varies (a contest, a bet) pick a line.
func success_text() -> String:
	return success_dialogue


## Whether a fulfilled request counts as handled (goals, achievements); a lost bet or
## contest does not.
func counts_as_success() -> bool:
	return true


## The reply after on_rejected().
func reject_text() -> String:
	return reject_dialogue


## The perk a success would grant, or null.
func perk_on_success(_brewery: Brewery) -> RunPerk:
	return granted_perk


## Every perk a success would grant; one at most unless a subclass offers more.
func perks_on_success(brewery: Brewery) -> Array[RunPerk]:
	var perks: Array[RunPerk] = []
	var perk: RunPerk = perk_on_success(brewery)
	if perk != null:
		perks.append(perk)
	return perks


## For requests that take a whole batch: highest quality first, then the larger `value`
## (what the batch is worth, or its servings).
static func is_better(quality: float, value: float, best_quality_so_far: float, best_value: float) -> bool:
	if not is_equal_approx(quality, best_quality_so_far):
		return quality > best_quality_so_far
	return value > best_value


## The fullest batch of `style`, so two batches of it never hide a big enough one.
func _find_batch_by_style(inventory: Inventory, style: BeerStyle.Style) -> BrewBatch:
	var best: BrewBatch = null
	for batch: BrewBatch in inventory.brew_batches:
		if batch.beer_style.style == style and (best == null or batch.amount_bottles > best.amount_bottles):
			best = batch
	return best


## Pays out a success: money, reputation, risk and perk, then takes `taken` out of storage.
func _settle(brewery: Brewery, taken: Dictionary) -> void:
	var money: float = money_on_success(brewery)
	var perks: Array[RunPerk] = perks_on_success(brewery)
	for batch: BrewBatch in taken:
		batch.amount_bottles -= taken[batch]
		if batch.amount_bottles <= 0:
			brewery.inventory.remove_batch(batch)
	brewery.change_money(snappedf(money, 0.1), MoneyLedger.Source.EVENTS)
	brewery.change_reputation(reward_reputation, ReputationRules.Source.EVENTS)
	if clears_risk:
		brewery.risk = 0
	else:
		brewery.add_risk(reward_risk)
	for perk: RunPerk in perks:
		brewery.apply_perk(perk)
