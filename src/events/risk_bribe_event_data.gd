class_name RiskBribeEventData
extends SpecialEventData

## The one direct, player-initiated way to bring LVV risk down: pay a bribe
## instead of handing over beer. Costs money (and typically a little
## reputation, via reward_reputation — bribery isn't exactly good PR) rather
## than requiring any bottles. Its .tres sets weighs_by_risk, so it shows up
## more often as risk climbs.

@export var bribe_cost: int = 40


## A payment settles on "Joo"; it never waits to take money or reputation later.
func waits_for_delivery() -> bool:
	return false


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < bribe_cost:
		return false

	brewery.change_money(-bribe_cost, MoneyLedger.Source.LVV)
	_settle(brewery, {})
	return true


## Takes no beer.
func servings_taken(_brewery: Brewery) -> Dictionary:
	return {}
