class_name PerkOfferEventData
extends SpecialEventData

## Someone sells an improvement (Keke's bartender course, the renovator's job): pay
## offer_cost on "Joo" and get perk_count different perks, rolled from offered_perks each
## time the event shows up (prepared()), as is the caller's name from caller_names.
## Only offered to a player who can pay.

@export var offer_cost: int = 100
## Kept out of the perks folder so they never show up on a level-up card.
@export var offered_perks: Array[RunPerk] = []
@export var perk_count: int = 1
## One is picked per visit; empty keeps event_caller_name.
@export var caller_names: Array[String] = []
## Rolled by prepared() and saved with an open window.
@export var rolled_perks: Array[RunPerk] = []


func get_weight(brewery: Brewery) -> float:
	return super(brewery) if brewery.money >= offer_cost else 0.0


func prepared(_brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	var rolled := duplicate() as PerkOfferEventData
	rolled.rolled_perks = pick_perks(offered_perks, perk_count)
	if not caller_names.is_empty():
		rolled.event_caller_name = caller_names.pick_random()
	return rolled


## `count` different perks from `pool` in random order, or all of them if it is smaller.
static func pick_perks(pool: Array[RunPerk], count: int) -> Array[RunPerk]:
	var shuffled: Array[RunPerk] = pool.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, mini(count, shuffled.size()))


## A payment settles on "Joo".
func waits_for_delivery() -> bool:
	return false


## Takes money, no beer.
func servings_taken(_brewery: Brewery) -> Dictionary:
	return {}


func perks_on_success(brewery: Brewery) -> Array[RunPerk]:
	return rolled_perks if not rolled_perks.is_empty() else super(brewery)


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < offer_cost:
		return false
	brewery.change_money(-offer_cost, MoneyLedger.Source.EVENTS)
	_settle(brewery, {})
	return true
