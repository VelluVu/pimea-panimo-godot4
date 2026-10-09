class_name RunPerk
extends Resource

## A buff picked on level-up (see LevelUpWindow) or granted permanently by a
## MetaUnlockData. Perks accumulate over a run and only ever strengthen it.
##
## Every stat defaults to neutral (1.0 for multipliers, 0 for flat values), so
## any number of perks combine. PerkStats lists the stats and how they show.

@export var perk_name: String = ""
@export var description: String = ""

## Placeholder until real art exists.
@export var icon_placeholder: String = "⭐"

## Weights PerkRegistry.get_random_perks() and colours the LevelUpWindow card.
## It does not change the stats. Values are tuned assuming repeat picks compound.
enum Tier { COMMON, RARE, LEGENDARY }
@export var tier: Tier = Tier.COMMON

## Flat addition to a batch's quality (may exceed 1.0).
@export var quality_bonus: float = 0.0
## Multiplies reputation gained from a sale.
@export var reputation_gain_multiplier: float = 1.0
## Multiplies the tip earned from a sale.
@export var tip_income_multiplier: float = 1.0
## Multiplies the raid threshold; above 1.0 gives more risk headroom.
@export var raid_threshold_multiplier: float = 1.0
## Multiplies bulk-sell and bar-shipment payouts, never counter sales.
@export var distribution_income_multiplier: float = 1.0
## Multiplies ingredient prices at the shop; below 1.0 is cheaper.
@export var ingredient_price_multiplier: float = 1.0
## Multiplies a brew's raw bottle yield, before bottling loss.
@export var brew_yield_multiplier: float = 1.0
## Chance (0 to 1, summed and capped) that a brew returns part of its ingredients.
@export var ingredient_refund_chance: float = 0.0
## Multiplies days to peak quality. Read once per brew and stored on the batch.
@export var peak_speed_multiplier: float = 1.0
## Multiplies daily quality loss past shelf life. Read once per brew, like peak_speed_multiplier.
@export var decline_rate_multiplier: float = 1.0
## Multiplies the wait before the next walk-in; below 1.0 brings customers faster.
@export var spawn_interval_multiplier: float = 1.0
## Multiplies how often an inspector (Agentti) customer is picked.
@export var agentti_appearance_multiplier: float = 1.0
## Multiplies how often a Mafioso customer is picked.
@export var mafioso_appearance_multiplier: float = 1.0
## Chance (0 to 1, summed and capped) that a sale's tip is doubled.
@export var tip_double_chance: float = 0.0
## Multiplies the chance a sale ends in a bar fight.
@export var bar_fight_chance_multiplier: float = 1.0
## Multiplies the listed price of a counter sale; the tip follows it.
@export var counter_price_multiplier: float = 1.0
## Multiplies the LVV risk a counter sale adds; below 1.0 draws less attention.
@export var sale_risk_multiplier: float = 1.0
## Multiplies the wait before the next group visit only, not walk-ins.
@export var group_event_interval_multiplier: float = 1.0
## Extra raids tolerated before the busted ending.
@export var extra_raid_strikes: int = 0
## Batches spared from confiscation in each raid.
@export var raid_hidden_batch_count: int = 0
## Counter spots added to the bar's default ones.
@export var extra_counter_slots: int = 0
## Daily goals rolled each day on top of GoalWiring.DAILY_GOAL_ROLLS.
@export var extra_daily_goal_rolls: int = 0
## Share (0 to 1, summed and capped) of each confiscated batch's bottles a raid leaves behind.
@export var raid_saved_bottle_share: float = 0.0
## Chance (0 to 1, summed and capped) on top of WalkInRules.BASE_COMPANY_CHANCE that a
## walk-in arrives with company.
@export var walk_in_company_chance: float = 0.0
## Extra customers in such a company beyond the usual one.
@export var walk_in_company_bonus: int = 0

## When true, multiplier stats add their delta from 1.0 instead of
## multiplying, so repeat picks grow in a straight line.
@export var stacks_additively: bool = false

## Set on the copies MetaUnlockData makes of Olutoppi nodes. Exported so a loaded run
## still tells them apart from level-up picks.
@export var is_permanent: bool = false


## Combines one stat over a list of perks: multiplicative by default, additive
## for perks with stacks_additively. `base` is the starting value (PerkStats
## passes 1.0). Static so it is testable without a Brewery.
static func combine_stacking(base : float, perks : Array[RunPerk], field_getter : Callable) -> float:
	var multiplier : float = base
	var additive_bonus : float = 0.0

	for perk : RunPerk in perks:
		var value : float = field_getter.call(perk)
		if perk.stacks_additively:
			additive_bonus += value - 1.0
		else:
			multiplier *= value

	return multiplier + additive_bonus


## A fresh perk with every stat scaled to `level`, for perks whose stats are authored
## per level (see PerkStats.scale_per_level()). Never mutates self: such resources are
## shared by every run.
func scaled_copy(level : int) -> RunPerk:
	return _copy_with(func(kind : PerkStats.Kind, value : float) -> Variant: return PerkStats.scale_per_level(kind, value, level))


## A fresh perk with every stat moved `strength` (0 to 1) of the way from neutral, for
## a reward that grows with how well something went. Counts round down.
func strength_copy(strength : float) -> RunPerk:
	return _copy_with(func(kind : PerkStats.Kind, value : float) -> Variant:
		var neutral : float = PerkStats.neutral_value(kind)
		var moved : float = neutral + (value - neutral) * strength
		if kind == PerkStats.Kind.COUNT:
			return floori(moved)
		return moved)


## A fresh perk with this one's name and look, and each stat as `stat_value(kind, value)`.
func _copy_with(stat_value : Callable) -> RunPerk:
	var copy := RunPerk.new()
	copy.perk_name = perk_name
	copy.description = description
	copy.icon_placeholder = icon_placeholder
	copy.tier = tier
	copy.stacks_additively = stacks_additively
	for entry : Dictionary in PerkStats.definitions():
		copy.set(entry.stat, stat_value.call(entry.kind, float(get(entry.stat))))
	return copy


## One short line per non-neutral stat, shown next to the perk's flavour text.
func get_stat_summary() -> String:
	var lines : PackedStringArray = []

	for entry : Dictionary in PerkStats.definitions():
		var kind : PerkStats.Kind = entry.kind
		var value : float = get(entry.stat)
		if value != PerkStats.neutral_value(kind):
			lines.append(tr(entry.text) % PerkStats.value_text(kind, value, stacks_additively))

	return "\n".join(lines)


func get_tier_label() -> String:
	match tier:
		Tier.RARE:
			return tr(StringContainer.PERK_TIER_RARE)
		Tier.LEGENDARY:
			return tr(StringContainer.PERK_TIER_LEGENDARY)
		_:
			return tr(StringContainer.PERK_TIER_COMMON)


const TIER_COLOR_COMMON : Color = Color.WHITE
const TIER_COLOR_RARE : Color = Color("4fa8ff")
const TIER_COLOR_LEGENDARY : Color = Color("ffb347")

func get_tier_color() -> Color:
	match tier:
		Tier.RARE:
			return TIER_COLOR_RARE
		Tier.LEGENDARY:
			return TIER_COLOR_LEGENDARY
		_:
			return TIER_COLOR_COMMON
