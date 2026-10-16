class_name RiskBribeEventData
extends SpecialEventData

## The one direct way to bring LVV risk down: pay money (and usually a little
## reputation) instead of beer. Its .tres sets weighs_by_risk, so it comes more often as
## risk climbs.

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
