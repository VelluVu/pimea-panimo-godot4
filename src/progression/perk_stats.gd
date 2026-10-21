class_name PerkStats
extends RefCounted

## Every active RunPerk folded into one number per stat, so a new perk axis is a field and a
## stat line. multiplier() multiplies (or adds, stacks_additively), total() sums, chance()
## sums and clamps to 0..1.

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
const TIP_CHANCE := &"tip_chance"
const INFECTION_REDUCTION := &"infection_reduction"
const BAR_FIGHT_CHANCE := &"bar_fight_chance_multiplier"
const COUNTER_PRICE := &"counter_price_multiplier"
const SALE_RISK := &"sale_risk_multiplier"
const EXTRA_RAID_STRIKES := &"extra_raid_strikes"
const RAID_HIDDEN_BATCHES := &"raid_hidden_batch_count"
const EXTRA_COUNTER_SLOTS := &"extra_counter_slots"
const EXTRA_DAILY_GOAL_ROLLS := &"extra_daily_goal_rolls"
const RAID_SAVED_BOTTLE_SHARE := &"raid_saved_bottle_share"
const WALK_IN_COMPANY_CHANCE := &"walk_in_company_chance"
const WALK_IN_COMPANY_BONUS := &"walk_in_company_bonus"
const EXTRA_MASH_CAPACITY := &"extra_mash_capacity_kg"

## MULTIPLIER is neutral at 1.0, shown as a change; PERCENT_ADD a fraction neutral at 0;
## COUNT a whole number.
enum Kind { MULTIPLIER, PERCENT_ADD, COUNT }

const ADDITIVE_PERCENT_FORMAT : String = "%d %%"
const MULTIPLICATIVE_PERCENT_FORMAT : String = "×%d %%"
const COUNT_FORMAT : String = "%d"


## Every stat in display order with its Finnish line; with the RunPerk field, the only place
## a new stat is registered. Values show unsigned, so the line says the direction and
## "increases" records it (test_perk_stats checks every perk resource against it).
static func definitions() -> Array[Dictionary]:
	return [
		{"stat": QUALITY_BONUS, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_QUALITY_STAT_STRING},
		{"stat": REPUTATION_GAIN, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_REPUTATION_STAT_STRING},
		{"stat": TIP_INCOME, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_TIP_STAT_STRING},
		{"stat": RAID_THRESHOLD, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_RAID_THRESHOLD_STAT_STRING},
		{"stat": DISTRIBUTION_INCOME, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_DISTRIBUTION_STAT_STRING},
		{"stat": INGREDIENT_PRICE, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_INGREDIENT_PRICE_STAT_STRING},
		{"stat": BREW_YIELD, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_YIELD_STAT_STRING},
		{"stat": INGREDIENT_REFUND_CHANCE, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_REFUND_CHANCE_STAT_STRING},
		{"stat": PEAK_SPEED, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_PEAK_SPEED_STAT_STRING},
		{"stat": DECLINE_RATE, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_DECLINE_RATE_STAT_STRING},
		{"stat": SPAWN_INTERVAL, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_SPAWN_INTERVAL_STAT_STRING},
		{"stat": WALK_IN_COMPANY_CHANCE, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_WALK_IN_COMPANY_CHANCE_STAT_STRING},
		{"stat": WALK_IN_COMPANY_BONUS, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_WALK_IN_COMPANY_BONUS_STAT_STRING},
		{"stat": AGENTTI_APPEARANCE, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_AGENTTI_APPEARANCE_STAT_STRING},
		{"stat": MAFIOSO_APPEARANCE, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_MAFIOSO_APPEARANCE_STAT_STRING},
		{"stat": TIP_CHANCE, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_TIP_CHANCE_STAT_STRING},
		{"stat": INFECTION_REDUCTION, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_INFECTION_REDUCTION_STAT_STRING},
		{"stat": TIP_DOUBLE_CHANCE, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_TIP_DOUBLE_CHANCE_STAT_STRING},
		{"stat": BAR_FIGHT_CHANCE, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_BAR_FIGHT_CHANCE_STAT_STRING},
		{"stat": COUNTER_PRICE, "kind": Kind.MULTIPLIER, "increases": true, "text": StringContainer.PERK_COUNTER_PRICE_STAT_STRING},
		{"stat": SALE_RISK, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_SALE_RISK_STAT_STRING},
		{"stat": GROUP_EVENT_INTERVAL, "kind": Kind.MULTIPLIER, "increases": false, "text": StringContainer.PERK_GROUP_EVENT_INTERVAL_STAT_STRING},
		{"stat": EXTRA_RAID_STRIKES, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_EXTRA_RAID_STRIKES_STAT_STRING},
		{"stat": RAID_HIDDEN_BATCHES, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_RAID_HIDDEN_BATCH_STAT_STRING},
		{"stat": RAID_SAVED_BOTTLE_SHARE, "kind": Kind.PERCENT_ADD, "increases": true, "text": StringContainer.PERK_RAID_SAVED_BOTTLE_SHARE_STAT_STRING},
		{"stat": EXTRA_COUNTER_SLOTS, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_EXTRA_COUNTER_SLOTS_STAT_STRING},
		{"stat": EXTRA_DAILY_GOAL_ROLLS, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_EXTRA_DAILY_GOAL_ROLLS_STAT_STRING},
		{"stat": EXTRA_MASH_CAPACITY, "kind": Kind.COUNT, "increases": true, "text": StringContainer.PERK_EXTRA_MASH_CAPACITY_STAT_STRING},
	]


static func neutral_value(kind : Kind) -> float:
	return 1.0 if kind == Kind.MULTIPLIER else 0.0


## The size of the change, unsigned since the stat line says the direction: additive
## "15 %", multiplicative "×15 %".
static func value_text(kind : Kind, value : float, additive : bool) -> String:
	match kind:
		Kind.MULTIPLIER:
			var format : String = ADDITIVE_PERCENT_FORMAT if additive else MULTIPLICATIVE_PERCENT_FORMAT
			return format % absi(display_number(kind, value))
		Kind.PERCENT_ADD:
			return ADDITIVE_PERCENT_FORMAT % absi(display_number(kind, value))
		_:
			return COUNT_FORMAT % absi(display_number(kind, value))


## The whole number a stat line shows: the percentage change, the percentage or the count.
static func display_number(kind : Kind, value : float) -> int:
	match kind:
		Kind.MULTIPLIER:
			return roundi((value - 1.0) * 100)
		Kind.PERCENT_ADD:
			return roundi(value * 100)
		_:
			return roundi(value)


## A per-level value scaled to `level`: multipliers re-based from neutral, others multiplied
## straight.
static func scale_per_level(kind : Kind, per_level : float, level : int) -> Variant:
	match kind:
		Kind.MULTIPLIER:
			return 1.0 + (per_level - 1.0) * level
		Kind.PERCENT_ADD:
			return per_level * level
		_:
			return roundi(per_level) * level


var _perks : Array[RunPerk]


func _init(perks : Array[RunPerk]) -> void:
	_perks = perks


## Multiplicative stat, starting from 1.0.
func multiplier(stat : StringName) -> float:
	return RunPerk.combine_stacking(1.0, _perks, func(perk : RunPerk) -> float: return perk.get(stat))


## Flat sum of a perk field. Works for int and float stats.
func total(stat : StringName) -> float:
	var sum : float = 0.0
	for perk : RunPerk in _perks:
		sum += perk.get(stat)
	return sum


## Probability stat: flat sum clamped to a guaranteed hit at most.
func chance(stat : StringName) -> float:
	return clampf(total(stat), 0.0, 1.0)


## Base threshold scaled by the perks' raid_threshold_multiplier.
func raid_threshold(base_threshold : int) -> int:
	return roundi(base_threshold * multiplier(RAID_THRESHOLD))
