class_name SpecialEventData
extends Resource

## Base special event: "bring N bottles of style X". Subclasses override
## try_fulfill() to implement a different mechanic entirely (quality
## thresholds, paying a bribe, donating raw ingredients, ...) while reusing
## the shared dialogue/reward/timeout fields and _settle() below.
## A request for goods waits after "Joo" (delivery_seconds) and completes itself once
## the stock is there (SpecialEventWindow); one that costs money or reputation settles
## on "Joo" (waits_for_delivery()).


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
## Given on each success; event perks live in src/resources/event_perks/, outside the
## perks folder, so they never show up on a level-up card.
@export var granted_perk: RunPerk
## Grows likelier as LVV risk climbs (see risk_weight()). Set on events that lower risk,
## so a player close to a raid sees a way out more often.
@export var weighs_by_risk: bool = false

## How many times as likely a weighs_by_risk event is at the raid threshold as at risk 0.
const MAX_RISK_WEIGHT_MULTIPLIER: float = 2.0


## Relative odds of this event being the one CustomerRegistry.
## get_random_special_event() rolls: 1.0, or risk_weight() for a weighs_by_risk
## event. Override in a subclass to bias it further (ReputationFavourEventData
## drops to 0 when the player cannot pay).
func get_weight(brewery: Brewery) -> float:
	return risk_weight(brewery) if weighs_by_risk else 1.0


## 1.0 at no risk, rising linearly to MAX_RISK_WEIGHT_MULTIPLIER at the effective raid
## threshold and capped there. Still a weighted roll, never a sure thing.
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


## Numbers an intro line can quote by name, like {servings} or {risk}, taken from the
## event's own data so a line never quotes a stale price after a balance change.
func intro_values() -> Dictionary:
	return {"servings": required_bottles, "money": reward_money, "risk": absi(reward_risk)}


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


## Attempts to satisfy this event against the given brewery, applying its
## side effects (consuming stock, changing money/reputation/risk) only on
## success. Returns whether it succeeded. Override in subclasses for a
## different requirement; call _settle() once the requirement is met.
func try_fulfill(brewery: Brewery) -> bool:
	var taken: Dictionary = servings_taken(brewery)
	if taken.is_empty():
		return false
	_settle(brewery, taken)
	return true


## What a success would pay right now. Subclasses that price the goods override it;
## the playtest bot reads it too, so it always matches what _settle() pays.
func money_on_success(_brewery: Brewery) -> float:
	return reward_money


## The batches a success would take, BrewBatch -> servings; empty when the goods are not
## there. Requests for something other than beer leave it empty.
func servings_taken(brewery: Brewery) -> Dictionary:
	var batch: BrewBatch = _find_batch_by_style(brewery.inventory, required_style)
	if batch == null or batch.amount_bottles < required_bottles:
		return {}
	return {batch: required_bottles}


## Called when the player lets the offer pass (the window times out); most events shrug.
func on_rejected(_brewery: Brewery) -> void:
	pass


## The reply after a success; events whose outcome varies (a contest, a bet) pick a line.
func success_text() -> String:
	return success_dialogue


## Whether a fulfilled request counts as a handled event (goals, achievements). A lost
## bet or contest was carried out but went against the brewery.
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
			brewery.inventory.brew_batches.erase(batch)
	brewery.change_money(snappedf(money, 0.1), MoneyLedger.Source.EVENTS)
	brewery.change_reputation(reward_reputation, ReputationRules.Source.EVENTS)
	if clears_risk:
		brewery.risk = 0
	else:
		brewery.add_risk(reward_risk)
	for perk: RunPerk in perks:
		brewery.apply_perk(perk)
