class_name PerkStats
extends RefCounted

## Read-only view that folds a run's RunModifier plus every active RunPerk
## into one effective number per stat. Replaces the ~20 hand-written
## Brewery.get_X_multiplier() getters: a new perk axis is now just a new
## RunPerk field (plus a stat-summary line) and never touches Brewery.
##
## Holds references, not copies, so it always reflects the perks it was
## built from. Get one through Brewery.stats, which rebuilds it per access
## because a loaded save replaces Brewery.active_perks wholesale.
##
## Three combination modes, matching how each RunPerk field is documented:
## multiplier() stacks multiplicatively (or additively, see RunPerk.
## stacks_additively), total() sums flat values, chance() sums then clamps
## to 0..1.

## Stat names are the RunPerk field they read.
const QUALITY_BONUS := &"quality_bonus"
const REPUTATION_GAIN := &"reputation_gain_multiplier"
const TIP_INCOME := &"tip_income_multiplier"
const RAID_THRESHOLD := &"raid_threshold_multiplier"
const DISTRIBUTION_INCOME := &"distribution_income_multiplier"
const INGREDIENT_PRICE := &"ingredient_price_multiplier"
const BREW_YIELD := &"brew_yield_multiplier"
const INGREDIENT_REFUND_CHANCE := &"ingredient_refund_chance"
const PEAK_SPEED := &"peak_speed_multiplier"
const DECLINE_RATE := &"decline_rate_multiplier"
const SPAWN_INTERVAL := &"spawn_interval_multiplier"
const GROUP_EVENT_INTERVAL := &"group_event_interval_multiplier"
const AGENTTI_APPEARANCE := &"agentti_appearance_multiplier"
const MAFIOSO_APPEARANCE := &"mafioso_appearance_multiplier"
const TIP_DOUBLE_CHANCE := &"tip_double_chance"
const BAR_FIGHT_CHANCE := &"bar_fight_chance_multiplier"
const COUNTER_PRICE := &"counter_price_multiplier"
const EXTRA_RAID_STRIKES := &"extra_raid_strikes"
const RAID_HIDDEN_BATCHES := &"raid_hidden_batch_count"

## How a stat is stored and shown. MULTIPLIER is neutral at 1.0 and shown as
## a percentage change, PERCENT_ADD is a flat fraction neutral at 0 and shown
## as a percentage, COUNT is a whole number neutral at 0.
enum Kind { MULTIPLIER, PERCENT_ADD, COUNT }


## Every perk stat in display order, with the Finnish line that shows it.
## The one place a new stat is registered besides its RunPerk field.
static func definitions() -> Array[Dictionary]:
	return [
		{"stat": QUALITY_BONUS, "kind": Kind.PERCENT_ADD, "text": StringContainer.PERK_QUALITY_STAT_STRING},
		{"stat": REPUTATION_GAIN, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_REPUTATION_STAT_STRING},
		{"stat": TIP_INCOME, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_TIP_STAT_STRING},
		{"stat": RAID_THRESHOLD, "kind": Kind.MULTIPLIER, "text": StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING},
		{"stat": DISTRIBUTION_INCOME, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_DISTRIBUTION_STAT_STRING},
		{"stat": INGREDIENT_PRICE, "kind": Kind.MULTIPLIER, "text": StringContainer.MODIFIER_INGREDIENT_PRICE_STAT_STRING},
		{"stat": BREW_YIELD, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_YIELD_STAT_STRING},
		{"stat": INGREDIENT_REFUND_CHANCE, "kind": Kind.PERCENT_ADD, "text": StringContainer.PERK_REFUND_CHANCE_STAT_STRING},
		{"stat": PEAK_SPEED, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_PEAK_SPEED_STAT_STRING},
		{"stat": DECLINE_RATE, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_DECLINE_RATE_STAT_STRING},
		{"stat": SPAWN_INTERVAL, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_SPAWN_INTERVAL_STAT_STRING},
		{"stat": AGENTTI_APPEARANCE, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_AGENTTI_APPEARANCE_STAT_STRING},
		{"stat": MAFIOSO_APPEARANCE, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_MAFIOSO_APPEARANCE_STAT_STRING},
		{"stat": TIP_DOUBLE_CHANCE, "kind": Kind.PERCENT_ADD, "text": StringContainer.PERK_TIP_DOUBLE_CHANCE_STAT_STRING},
		{"stat": BAR_FIGHT_CHANCE, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_BAR_FIGHT_CHANCE_STAT_STRING},
		{"stat": COUNTER_PRICE, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_COUNTER_PRICE_STAT_STRING},
		{"stat": GROUP_EVENT_INTERVAL, "kind": Kind.MULTIPLIER, "text": StringContainer.PERK_GROUP_EVENT_INTERVAL_STAT_STRING},
		{"stat": EXTRA_RAID_STRIKES, "kind": Kind.COUNT, "text": StringContainer.PERK_EXTRA_RAID_STRIKES_STAT_STRING},
		{"stat": RAID_HIDDEN_BATCHES, "kind": Kind.COUNT, "text": StringContainer.PERK_RAID_HIDDEN_BATCH_STAT_STRING},
	]


static func neutral_value(kind : Kind) -> float:
	return 1.0 if kind == Kind.MULTIPLIER else 0.0


## The whole number a stat line shows: the percentage change, the percentage,
## or the count.
static func display_number(kind : Kind, value : float) -> int:
	match kind:
		Kind.MULTIPLIER:
			return roundi((value - 1.0) * 100)
		Kind.PERCENT_ADD:
			return roundi(value * 100)
		_:
			return roundi(value)


## A per-level authored value scaled to `level`: multipliers are re-based from
## neutral, flat values and counts multiply straight through.
static func scale_per_level(kind : Kind, per_level : float, level : int) -> Variant:
	match kind:
		Kind.MULTIPLIER:
			return 1.0 + (per_level - 1.0) * level
		Kind.PERCENT_ADD:
			return per_level * level
		_:
			return roundi(per_level) * level


var _modifier : RunModifier
var _perks : Array[RunPerk]


func _init(modifier : RunModifier, perks : Array[RunPerk]) -> void:
	_modifier = modifier
	_perks = perks


## Multiplicative stat. Starts from the run modifier's own field of the
## same name when it has one (its fixed starting conditions), else 1.0.
func multiplier(stat : StringName) -> float:
	var base : float = 1.0
	if _modifier != null and stat in _modifier:
		base = _modifier.get(stat)
	return RunPerk.combine_stacking(base, _perks, func(perk : RunPerk) -> float: return perk.get(stat))


## Flat sum of a perk field, added to the modifier's field when it has one
## (only quality_bonus does). Works for int and float stats.
func total(stat : StringName) -> float:
	var sum : float = 0.0
	if _modifier != null and stat in _modifier:
		sum += _modifier.get(stat)
	for perk : RunPerk in _perks:
		sum += perk.get(stat)
	return sum


## Probability stat: flat sum clamped to a guaranteed hit at most.
func chance(stat : StringName) -> float:
	return clampf(total(stat), 0.0, 1.0)


## Base threshold scaled by the modifier's lvv_threshold_multiplier and the
## perks' raid_threshold_multiplier. The two fields have different names,
## so this can't go through multiplier().
func raid_threshold(base_threshold : int) -> int:
	var start : float = _modifier.lvv_threshold_multiplier if _modifier != null else 1.0
	var combined : float = RunPerk.combine_stacking(start, _perks, func(perk : RunPerk) -> float: return perk.raid_threshold_multiplier)
	return roundi(base_threshold * combined)
