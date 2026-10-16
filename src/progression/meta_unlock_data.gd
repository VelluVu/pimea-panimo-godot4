class_name MetaUnlockData
extends RunPerk

## A leveled RunPerk bought with renown (MetaProgressManager.purchase_next_level()) and
## active from day 1 of every run; Brewery._seed_meta_perks() folds it into active_perks,
## so the usual perk maths applies. Its own type so a shop unlock can never slip into
## PerkRegistry's level-up pool.

## Which Olutoppi tree column this node belongs to — see olutoppi_window.gd.
enum Path { BAR_WORK, BREWING, MARKETING }
@export var path : Path = Path.BAR_WORK

## Persistence key in MetaProgressManager's ConfigFile: a readable slug, unique across
## every MetaUnlockData (test_meta_progress_manager.gd checks).
@export var unlock_id : String = ""

## How many times this node can be leveled (1-5, per the design brief) —
## a node that only ever grants a single flat bonus just sets this to 1.
@export var max_level : int = 3
## Flat renown price of each individual level — not escalating per level,
## the simplest reading of "depending on the cost and the passive reward"
## as a per-node property rather than inventing a compounding formula.
@export var renown_cost_per_level : int = 25

## unlock_ids that need at least one point before this node can be bought; empty for a
## path's root. Several entries make a capstone that needs all of them, unless
## requires_any_prerequisite is set.
@export var prerequisite_ids : Array[String] = []

## Needs only one prerequisite_ids entry invested, for a capstone reachable through
## either branch (Piilokätkö).
@export var requires_any_prerequisite : bool = false


## Inherited stats are authored per level. Returns a fresh RunPerk scaled to `level`
## (PerkStats.scale_per_level()), always linearly; stacks_additively only decides how the
## total combines with other perks. Never mutates self: the pool is shared between runs.
func get_scaled_perk(level : int) -> RunPerk:
	var scaled : RunPerk = scaled_copy(level)
	scaled.is_permanent = true
	return scaled
