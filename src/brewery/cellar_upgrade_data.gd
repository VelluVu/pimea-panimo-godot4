class_name CellarUpgradeData
extends RunPerk

## A cellar upgrade bought with money during a run, up to max_level times. Like
## MetaUnlockData, every inherited RunPerk stat is authored as its per-level step and
## scaled with scaled_copy(), so the upgrade feeds PerkStats like any other perk.

## Stable key for Brewery.cellar_upgrade_levels and the save. Must be unique.
@export var upgrade_id : String = ""
## Order in the upgrades window.
@export var sort_order : int = 0
@export var max_level : int = 5
## Price of the first level; each next level costs cost_growth times the previous.
@export var base_cost : int = 50
@export var cost_growth : float = 1.8


## Price of the level after `level`, see CellarUpgradeRules.
func cost_for_next_level(level : int) -> int:
	return CellarUpgradeRules.level_cost(base_cost, cost_growth, level)
