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
## capstone (ALL listed prerequisites required, not just one) — see
## olutoppi_window.tscn's tree layout, where a capstone's two branches
## merge back into it.
@export var prerequisite_ids : Array[String] = []


## Every inherited RunPerk stat field on this resource (quality_bonus,
## reputation_gain_multiplier, etc.) is authored as its PER-LEVEL
## increment, not a total — e.g. quality_bonus = 0.01 means +0.01 per
## invested level. Returns a fresh RunPerk with those increments scaled by
## level: additive fields multiply straight through (level * increment),
## multiplicative fields are re-based from neutral (1.0 + (increment -
## 1.0) * level). Never mutates self — unlock_pool entries are shared
## singleton resources loaded once by MetaProgressManager, reused by
## every run; scaling has to produce a new instance instead.
##
## This formula always grows a node's OWN levels linearly, regardless of
## stacks_additively — that flag only ends up controlling how this node's
## already-scaled total then combines with *other* perks/modifiers in
## RunPerk.combine_stacking() (Brewery.get_reputation_gain_multiplier()
## and its siblings), not how this node's levels accumulate internally.
## A genuinely compounding node (levels multiplying against each other)
## would need a different formula (pow(increment, level)) — not supported
## here, every shipped node is linear-per-level by design.
func get_scaled_perk(level : int) -> RunPerk:
	var scaled := RunPerk.new()
	scaled.perk_name = perk_name
	scaled.description = description
	scaled.icon_placeholder = icon_placeholder
	scaled.tier = tier
	scaled.quality_bonus = quality_bonus * level
	scaled.reputation_gain_multiplier = _scale_multiplier(reputation_gain_multiplier, level)
	scaled.tip_income_multiplier = _scale_multiplier(tip_income_multiplier, level)
	scaled.raid_threshold_multiplier = _scale_multiplier(raid_threshold_multiplier, level)
	scaled.distribution_income_multiplier = _scale_multiplier(distribution_income_multiplier, level)
	scaled.ingredient_price_multiplier = _scale_multiplier(ingredient_price_multiplier, level)
	scaled.brew_yield_multiplier = _scale_multiplier(brew_yield_multiplier, level)
	scaled.ingredient_refund_chance = ingredient_refund_chance * level
	scaled.peak_speed_multiplier = _scale_multiplier(peak_speed_multiplier, level)
	scaled.decline_rate_multiplier = _scale_multiplier(decline_rate_multiplier, level)
	scaled.spawn_interval_multiplier = _scale_multiplier(spawn_interval_multiplier, level)
	scaled.agentti_appearance_multiplier = _scale_multiplier(agentti_appearance_multiplier, level)
	scaled.mafioso_appearance_multiplier = _scale_multiplier(mafioso_appearance_multiplier, level)
	scaled.tip_double_chance = tip_double_chance * level
	scaled.bar_fight_chance_multiplier = _scale_multiplier(bar_fight_chance_multiplier, level)
	scaled.counter_price_multiplier = _scale_multiplier(counter_price_multiplier, level)
	scaled.group_event_interval_multiplier = _scale_multiplier(group_event_interval_multiplier, level)
	scaled.extra_raid_strikes = extra_raid_strikes * level
	scaled.raid_hidden_batch_count = raid_hidden_batch_count * level
	scaled.stacks_additively = stacks_additively
	return scaled


static func _scale_multiplier(per_level_value : float, level : int) -> float:
	return 1.0 + (per_level_value - 1.0) * level
