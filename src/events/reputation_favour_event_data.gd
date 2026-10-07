class_name ReputationFavourEventData
extends SpecialEventData

## Someone wants to borrow the brewery's good name: the player pays in reputation
## instead of beer or money. Only offered once the player has enough to pay.

@export var reputation_cost: int = 20


func get_weight(brewery: Brewery) -> float:
	return affordable_weight(brewery.reputation, reputation_cost, super.get_weight(brewery))


## `base_weight`, or 0 so the favour is never offered to a player who cannot pay.
static func affordable_weight(reputation: int, cost: int, base_weight: float) -> float:
	return base_weight if reputation >= cost else 0.0


## A payment settles on "Joo"; it never waits to take money or reputation later.
func waits_for_delivery() -> bool:
	return false


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.reputation < reputation_cost:
		return false

	brewery.change_reputation(-reputation_cost, ReputationRules.Source.EVENTS)
	_apply_rewards(brewery)
	return true
