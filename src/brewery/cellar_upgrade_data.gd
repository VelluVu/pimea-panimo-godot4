class_name CellarUpgradeData
extends RunPerk

## A cellar upgrade bought during a run, up to max_level times. Its RunPerk stats are
## per-level steps scaled by scaled_copy(), so it feeds PerkStats like any perk.

## Stable key for Brewery.cellar_upgrade_levels and the save. Must be unique.
@export var upgrade_id : String = ""
## Order in the upgrades window.
@export var sort_order : int = 0
@export var max_level : int = 5
## Price of the first level; each next level costs cost_growth times the previous.
@export var base_cost : int = 50
@export var cost_growth : float = 1.8
## Empty clean kegs each level adds to the cellar, see KegRules.
@export var kegs_per_level : int = 0
## A machine is bought once and owned in every later season, with an on/off switch;
## see CellarMachines.
@export var is_machine : bool = false


## Price of the level after `level`, see CellarUpgradeRules.
func cost_for_next_level(level : int) -> int:
	return CellarUpgradeRules.level_cost(base_cost, cost_growth, level)
