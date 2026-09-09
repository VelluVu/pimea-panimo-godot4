class_name SpecialEventData
extends Resource

## Base special event: "bring N bottles of style X". Subclasses override
## try_fulfill() to implement a different mechanic entirely (quality
## thresholds, paying a bribe, donating raw ingredients, ...) while reusing
## the shared dialogue/reward/timeout fields and _apply_rewards() below.


@export var event_caller_name: String = "Kaljabisnesmies"
@export var intro_dialogue: String = "Nyt pitäs saada reippaasti kaljaa kaikille, eli bulkkia vähintään 20 pulloa!"
@export var success_dialogue: String = "Nyt bileet pystyyn!"
@export var fail_dialogue: String = "Eikö täältä räkälästä saa ees bulkkii kaikille?"
@export var reject_dialogue : String = "Päätit olla tarttumatta tarjoukseen. Jatketaan pimeää bisnestä."
@export var timeout_seconds: float = 10.0

@export_group("Vaatimus")
@export var required_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var required_bottles: int = 20

@export_group("Palkkiot")
@export var reward_money: int = 70
@export var reward_reputation: int = 10
@export var reward_risk: int = 5
@export var clears_risk: bool = false


## Attempts to satisfy this event against the given brewery, applying its
## side effects (consuming stock, changing money/reputation/risk) only on
## success. Returns whether it succeeded. Override in subclasses for a
## different requirement; call _apply_rewards() once the requirement is met.
func try_fulfill(brewery: Brewery) -> bool:
	var matching_batch := _find_batch_by_style(brewery, required_style)
	if matching_batch == null or matching_batch.amount_bottles < required_bottles:
		return false

	matching_batch.amount_bottles -= required_bottles
	_apply_rewards(brewery)

	if matching_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(matching_batch)

	return true


func _find_batch_by_style(brewery: Brewery, style: BeerStyle.Style) -> BrewBatch:
	for batch: BrewBatch in brewery.inventory.brew_batches:
		if batch.beer_style.style == style:
			return batch
	return null


func _apply_rewards(brewery: Brewery) -> void:
	brewery.money += reward_money
	brewery.reputation = max(0, brewery.reputation + reward_reputation)
	if clears_risk:
		brewery.clear_risk()
	else:
		brewery.add_risk(reward_risk)
