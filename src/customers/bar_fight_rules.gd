class_name BarFightRules
extends RefCounted

## When a visit turns into a bar fight: the customer's trigger
## (CustomerData.bar_fight_trigger) must be met, then bar_fight_chance, scaled by perks.


## `wanted` is how many bottles the customer came for, `bought` how many they got
## (0 when turned away). `min_bought` is the BOUGHT_MANY threshold.
static func is_triggered(trigger: CustomerData.BarFightTrigger, wanted: int, bought: int, min_bought: int) -> bool:
	match trigger:
		CustomerData.BarFightTrigger.NOT_ENOUGH_BEER:
			return bought < wanted
		CustomerData.BarFightTrigger.BOUGHT_MANY:
			return bought > 0 and bought >= min_bought
	# RANDOM: any completed sale can turn into a fight.
	return bought > 0


## `roll` is randf(), passed in for tests.
static func breaks_out(data: CustomerData, wanted: int, bought: int, chance_multiplier: float, roll: float) -> bool:
	if data.bar_fight_chance <= 0.0:
		return false
	if not is_triggered(data.bar_fight_trigger, wanted, bought, data.bar_fight_min_bottles_bought):
		return false
	return roll < data.bar_fight_chance * chance_multiplier
