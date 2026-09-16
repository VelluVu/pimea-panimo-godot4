class_name RunPerk
extends Resource

## A small permanent-for-this-run buff picked on level-up — see
## Brewery.add_xp()/apply_perk() and LevelUpWindow. Unlike RunModifier
## (rolled once, fixed for the whole run, shapes risk/pricing), perks
## accumulate over a run and only ever make things stronger — the
## roguelike "you're growing" half of the loop, where RunModifier is the
## "this run's starting conditions" half.
##
## Each field defaults to neutral (1.0 for multipliers, 0.0 for flat
## bonuses) so multiple perks — including repeats of the same one, see
## PerkRegistry.get_random_perks() — stack by simple multiplication/
## addition in Brewery's get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier().

@export var perk_name: String = ""
@export var description: String = ""

## Same "no real art yet" convention as RunModifier.icon_placeholder.
@export var icon_placeholder: String = "⭐"

## Purely a weighting hint for PerkRegistry.get_random_perks() (see its
## TIER_WEIGHTS) and a display cue on LevelUpWindow's cards — doesn't
## change how a picked perk's own stat fields apply. Existing perks are
## tiered by their own numeric magnitude per stat axis (e.g. the three
## quality perks: +0.06 common, +0.10 rare, +0.15 legendary) rather than
## anything arbitrary. Kept deliberately modest — get_random_perks()
## allows repeat picks of the same perk across separate level-ups (see
## its own docstring), and every multiplier field here stacks by
## multiplication, so even a "small" per-pick bonus compounds fast over
## several repeats; these values are tuned assuming that stacking, not
## a single pick in isolation.
enum Tier { COMMON, RARE, LEGENDARY }
@export var tier: Tier = Tier.COMMON

## Flat addition to a brewed batch's original_quality (quality is already
## known to exceed 1.0 for a masterful batch — see BrewResolver — so this
## isn't clamped).
@export var quality_bonus: float = 0.0

## Multiplies the reputation gained from a sale (see CustomerManager.
## process_auto_sale()).
@export var reputation_gain_multiplier: float = 1.0

## Multiplies the tip earned from a sale (see CustomerManager.
## process_auto_sale()).
@export var tip_income_multiplier: float = 1.0

## Multiplies Brewery.LVV_RAID_THRESHOLD alongside RunModifier's own
## lvv_threshold_multiplier (see Brewery.get_effective_raid_threshold()) —
## same field/meaning as RunModifier's, just accumulating mid-run instead
## of being fixed at run start. Above 1.0 means more risk headroom before
## a raid triggers.
@export var raid_threshold_multiplier: float = 1.0

## Multiplies the payout from Brewery.bulk_sell/ship_batch_to_bar — the
## warehouse's two distribution actions (see Brewery.
## get_distribution_income_multiplier()). Doesn't touch a normal
## counter sale at all, so this is a build-defining pick only for a run
## actually leaning on the warehouse instead of walk-in customers.
@export var distribution_income_multiplier: float = 1.0

## Whether this perk's multiplier fields above (reputation_gain_
## multiplier, tip_income_multiplier, raid_threshold_multiplier,
## distribution_income_multiplier — NOT quality_bonus, which was already
## flat addition from the start) stack by ADDING their delta from 1.0 to
## a running total instead of multiplying it in — see
## combine_stacking()/Brewery.get_reputation_gain_multiplier() and its
## siblings. False (the default) is the original multiplicative
## behavior: fast, compounding growth, ideal for going all-in on one
## stat, but explosive with repeat picks (see PerkRegistry.
## get_random_perks() — the same perk can be picked again at a later
## level-up). True grows in a straight line no matter how many times
## it's picked — slower, but predictable, and the only way a perk that
## touches several axes at once (like "Monitaituri" below) can stay
## "slight" even if the player happens to draw it more than once.
@export var stacks_additively: bool = false


## Shared combination logic for every axis that supports both stacking
## modes (see stacks_additively above) — a plain static function over a
## perk list + a field-reading Callable so it's directly unit-testable
## without a live Brewery, same "extract the pure math" reasoning as
## Brewery.calculate_bulk_sell_payout()/calculate_ship_payout(). base is
## the starting value before any perk is applied (a RunModifier's own
## multiplier, or 1.0 for an axis RunModifier doesn't touch).
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


## Formats this perk's own numeric fields as a short stat line, one per
## non-neutral field — used to put real numbers next to the flavor text on
## LevelUpWindow's cards and in RunEffectsWindow, instead of leaving the
## player to guess what e.g. "hieman laadukkaampi" actually means.
func get_stat_summary() -> String:
	var lines : PackedStringArray = []

	if quality_bonus != 0.0:
		lines.append(StringContainer.PERK_QUALITY_STAT_STRING % roundi(quality_bonus * 100))
	if reputation_gain_multiplier != 1.0:
		lines.append(StringContainer.PERK_REPUTATION_STAT_STRING % roundi((reputation_gain_multiplier - 1.0) * 100))
	if tip_income_multiplier != 1.0:
		lines.append(StringContainer.PERK_TIP_STAT_STRING % roundi((tip_income_multiplier - 1.0) * 100))
	if raid_threshold_multiplier != 1.0:
		lines.append(StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING % roundi((raid_threshold_multiplier - 1.0) * 100))
	if distribution_income_multiplier != 1.0:
		lines.append(StringContainer.PERK_DISTRIBUTION_STAT_STRING % roundi((distribution_income_multiplier - 1.0) * 100))

	if stacks_additively and not lines.is_empty():
		lines.append(StringContainer.PERK_ADDITIVE_STACKING_HINT)

	return "\n".join(lines)


func get_tier_label() -> String:
	match tier:
		Tier.RARE:
			return StringContainer.PERK_TIER_RARE
		Tier.LEGENDARY:
			return StringContainer.PERK_TIER_LEGENDARY
		_:
			return StringContainer.PERK_TIER_COMMON


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
