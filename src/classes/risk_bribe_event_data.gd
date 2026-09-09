class_name RiskBribeEventData
extends SpecialEventData

## The one direct, player-initiated way to bring AVI risk down: pay a bribe
## instead of handing over beer. Costs money (and typically a little
## reputation, via reward_reputation — bribery isn't exactly good PR) rather
## than requiring any bottles.

@export var bribe_cost: int = 40


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < bribe_cost:
		return false

	brewery.money -= bribe_cost
	_apply_rewards(brewery)
	return true
