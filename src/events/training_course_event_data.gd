class_name TrainingCourseEventData
extends SpecialEventData

## Someone sells a course: pay course_cost on "Joo" and learn one perk, rolled from
## course_perks each time the event shows up (prepared()). Only offered to a player who
## can pay.

@export var course_cost: int = 100
## Kept out of the perks folder so they never show up on a level-up card.
@export var course_perks: Array[RunPerk] = []
## Rolled by prepared() and saved with an open window.
@export var rolled_perk: RunPerk


func get_weight(brewery: Brewery) -> float:
	return super(brewery) if brewery.money >= course_cost else 0.0


func prepared(_brewery: Brewery, _bars: Array[BarContact]) -> SpecialEventData:
	if course_perks.is_empty():
		return self
	var rolled := duplicate() as TrainingCourseEventData
	rolled.rolled_perk = course_perks.pick_random()
	return rolled


## A payment settles on "Joo".
func waits_for_delivery() -> bool:
	return false


## Takes money, no beer.
func servings_taken(_brewery: Brewery) -> Dictionary:
	return {}


func perk_on_success(_brewery: Brewery) -> RunPerk:
	return rolled_perk if rolled_perk != null else granted_perk


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < course_cost:
		return false
	brewery.change_money(-course_cost, MoneyLedger.Source.EVENTS)
	_settle(brewery, {})
	return true
