class_name RiskBribeEventData
extends SpecialEventData

## The one direct, player-initiated way to bring LVV risk down: pay a bribe
## instead of handing over beer. Costs money (and typically a little
## reputation, via reward_reputation — bribery isn't exactly good PR) rather
## than requiring any bottles. Its .tres sets weighs_by_risk, so it shows up
## more often as risk climbs.

@export var bribe_cost: int = 40


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < bribe_cost:
		return false

	brewery.change_money(-bribe_cost, MoneyLedger.Source.LVV)
	_apply_rewards(brewery)
	return true
