class_name MetaUnlockData
extends RunPerk

## A leveled RunPerk bought with renown, active from day 1 of every run like any perk. Its
## own type so it never slips into the level-up pool.

## The Olutoppi column this node is in.
enum Path { BAR_WORK, BREWING, MARKETING }
@export var path : Path = Path.BAR_WORK

## The save key: a readable slug, unique across nodes (a test checks).
@export var unlock_id : String = ""

## How many times this node can be leveled (1 to 5).
@export var max_level : int = 3
## Renown per level, flat.
@export var renown_cost_per_level : int = 25

## Nodes that need a point first; empty for a root. Several make a capstone needing all,
## unless requires_any_prerequisite.
@export var prerequisite_ids : Array[String] = []

## Needs only one prerequisite_ids entry invested, for a capstone reachable through
## either branch (Piilokätkö).
@export var requires_any_prerequisite : bool = false


## A fresh RunPerk scaled linearly to `level` from per-level stats; stacks_additively only
## decides how it combines. Never mutates self: runs share it.
func get_scaled_perk(level : int) -> RunPerk:
	var scaled : RunPerk = scaled_copy(level)
	scaled.is_permanent = true
	return scaled
