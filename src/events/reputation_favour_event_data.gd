class_name ReputationFavourEventData
extends SpecialEventData

## Someone borrows the brewery's good name for reputation instead of beer or money, offered
## only when it can be paid. At cost 0 a plain offer (the journalist's story).

@export var reputation_cost: int = 20


func get_weight(brewery: Brewery) -> float:
	return affordable_weight(brewery.reputation, reputation_cost, super.get_weight(brewery))


func intro_values() -> Dictionary:
	var values: Dictionary = super()
	values["reputation"] = reputation_cost
	return values


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
	_settle(brewery, {})
	return true


## Takes no beer.
func servings_taken(_brewery: Brewery) -> Dictionary:
	return {}
