class_name ReputationFavourEventData
extends SpecialEventData

## Someone wants to borrow the brewery's good name: the player pays in reputation
## instead of beer or money. Only offered once the player has enough to pay.

@export var reputation_cost: int = 20
## Grows likelier as LVV risk climbs, like RiskBribeEventData. For favours that cut risk.
@export var weighs_by_risk: bool = false


func get_weight(brewery: Brewery) -> float:
	var base_weight: float = RiskBribeEventData.risk_weight(brewery) if weighs_by_risk else 1.0
	return affordable_weight(brewery.reputation, reputation_cost, base_weight)


## `base_weight`, or 0 so the favour is never offered to a player who cannot pay.
static func affordable_weight(reputation: int, cost: int, base_weight: float) -> float:
	return base_weight if reputation >= cost else 0.0


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.reputation < reputation_cost:
		return false

	brewery.change_reputation(-reputation_cost)
	_apply_rewards(brewery)
	return true
