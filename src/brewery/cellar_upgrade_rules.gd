class_name CellarUpgradeRules
extends RefCounted

## Prices and purchase checks for cellar upgrades.

## Prices are rounded to this, so the shop shows tidy numbers.
const PRICE_STEP : int = 5


## Price of going from `level` to `level + 1`: base_cost at level 0, growing by
## `growth` each level after.
static func level_cost(base_cost : int, growth : float, level : int) -> int:
	var raw : float = base_cost * pow(growth, maxi(0, level))
	return maxi(PRICE_STEP, roundi(raw / PRICE_STEP) * PRICE_STEP)


static func is_maxed(level : int, max_level : int) -> bool:
	return level >= max_level


static func can_buy(level : int, max_level : int, cost : int, money : float) -> bool:
	return not is_maxed(level, max_level) and money >= cost
