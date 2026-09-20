class_name MetaUnlockData
extends RunPerk

## A permanently-purchasable, LEVELED RunPerk: same stat axes
## (quality_bonus, reputation_gain_multiplier, tip_income_multiplier,
## raid_threshold_multiplier, distribution_income_multiplier,
## ingredient_price_multiplier) as a mid-run level-up perk, just bought
## with renown (MetaProgressManager.purchase_next_level()) up to max_level
## times instead of rolled once on level-up — and then active from day 1
## of every future run instead of accumulating mid-run. See
## Brewery._seed_meta_perks(), which folds every invested node's
## get_scaled_perk() result straight into active_perks so every existing
## get_quality_bonus()/get_reputation_gain_multiplier()/etc. aggregation
## on RunPerk just works unchanged — no separate math path needed.
##
## Deliberately its own resource type rather than a bare RunPerk with
## bolted-on fields: conflating "rolled for free on level-up, this run
## only" with "bought incrementally, permanent" under one type would make
## it easy to accidentally load a shop-only unlock into PerkRegistry's
## level-up pool (or vice versa) since both would satisfy `is RunPerk`.

## Which Olutoppi tree column this node belongs to — see olutoppi_window.gd.
enum Path { BAR_WORK, BREWING, MARKETING }
@export var path : Path = Path.BAR_WORK

## Stable persistence key for MetaProgressManager's ConfigFile — unlike
## IngredientData's numeric id (this project's other precedent for
## folder-loaded resources needing a persisted identity), a short string
## slug reads directly in the save file and never collides with an
## unrelated numbering scheme. Must be unique across every shipped
## MetaUnlockData — see test_meta_progress_manager.gd's duplicate check.
@export var unlock_id : String = ""

## How many times this node can be leveled (1-5, per the design brief) —
## a node that only ever grants a single flat bonus just sets this to 1.
@export var max_level : int = 3
## Flat renown price of each individual level — not escalating per level,
## the simplest reading of "depending on the cost and the passive reward"
## as a per-node property rather than inventing a compounding formula.
@export var renown_cost_per_level : int = 25

## unlock_id(s) of every node that must have at least 1 point invested
## before THIS node can be purchased at all — see
## MetaProgressManager.meets_prerequisites()/purchase_next_level(). Empty
## for a path's root node. More than one entry means a converging
## capstone; by default ALL listed prerequisites are required (see
## olutoppi_window.tscn's tree layout, where a capstone's branches merge
## back into it) — override with requires_any_prerequisite below for a
## capstone reachable via any single one of its branches instead.
@export var prerequisite_ids : Array[String] = []

## When true, meets_prerequisites() only needs ONE entry in
## prerequisite_ids invested (min level 1), not every one of them — see
## Piilokätkö (raid_piilokatko), Markkinointi's final node, reachable
## through either of its two feeder branches (Tukkuhinnat/Vahva brändi)
## rather than requiring both.
@export var requires_any_prerequisite : bool = false


## Every inherited RunPerk stat on this resource is authored as its PER-LEVEL
## increment, not a total. Returns a fresh RunPerk scaled to `level` (see
## PerkStats.scale_per_level()). Never mutates self: unlock_pool entries are
## shared resources reused by every run.
##
## Levels always grow linearly, whatever stacks_additively says; that flag only
## controls how the scaled total combines with other perks.
func get_scaled_perk(level : int) -> RunPerk:
	var scaled := RunPerk.new()
	scaled.perk_name = perk_name
	scaled.description = description
	scaled.icon_placeholder = icon_placeholder
	scaled.tier = tier
	scaled.stacks_additively = stacks_additively
	for entry : Dictionary in PerkStats.definitions():
		scaled.set(entry.stat, PerkStats.scale_per_level(entry.kind, get(entry.stat), level))
	return scaled
