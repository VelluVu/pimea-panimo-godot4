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

## Multiplies IngredientData.base_price at the buy/sell counter — see
## Brewery.get_ingredient_price_multiplier(). Same neutral-1.0/below-1.0-
## is-cheaper semantics as RunModifier's own field of the same name, just
## accumulating mid-run (or permanently, for a MetaUnlockData) instead of
## being fixed at run start.
@export var ingredient_price_multiplier: float = 1.0

## Multiplies a brewed batch's raw bottle yield before bottling loss is
## subtracted (see Brewery.get_brew_yield_multiplier()/start_brew()) —
## above 1.0 means more bottles out of the same recipe. Deliberately a
## bonus to the RAW yield rather than a reduction to BrewResolver.
## BOTTLE_LOSS_RATE: the loss rate also feeds BrewResolver's cost-basis/
## payout math (see get_ingredient_price_multiplier()'s docstring for the
## same "don't leak a personal-skill bonus into the run's structural
## pricing" reasoning), so touching it there would have nerfed unrelated
## sell payouts. This field only ever multiplies the actual yield of a
## real brew.
@export var brew_yield_multiplier: float = 1.0

## Chance (0.0-1.0), rolled once per brew in Brewery.start_brew(), that a
## flat fraction of the ingredients that brew just consumed come back to
## inventory — see Brewery.REFUND_FRACTION and get_ingredient_refund_chance().
## Neutral at 0.0, unlike every multiplier field above — summed by a plain
## loop across active_perks (same shape as quality_bonus), not
## combine_stacking(), since "probability" has no sensible multiplicative
## stacking mode. Clamped to 1.0 by get_ingredient_refund_chance() so
## several stacked perks can't push it past a guaranteed refund.
@export var ingredient_refund_chance: float = 0.0

## Multiplies BeerStyle.peak_days for a batch brewed while this perk is
## active — below 1.0 means fewer days to reach peak quality. Unlike every
## other field on this class, this and decline_rate_multiplier are read
## only ONCE, at the moment Brewery.start_brew() creates a new BrewBatch
## (see Brewery.get_peak_speed_multiplier()) — the batch snapshots the
## combined value onto its own peak_days_multiplier field rather than
## reading active_perks continuously, same "batch is self-contained data"
## reasoning as original_quality/final_ebc/etc. already being copied onto
## the batch at creation instead of recomputed later.
@export var peak_speed_multiplier: float = 1.0

## Multiplies how much quality a batch loses per day once past its shelf
## life (see BrewBatch._calculate_current_quality()) — below 1.0 means
## slower decline. Same brew-time-snapshot reasoning as
## peak_speed_multiplier above; see Brewery.get_decline_rate_multiplier().
@export var decline_rate_multiplier: float = 1.0

## Multiplies the randf_range() window CustomerSpawner rolls a solo walk-
## in's/group visit's next spawn delay from (see Brewery.get_spawn_
## interval_multiplier() and CustomerSpawner._start_next_walk_in_timer()/
## _start_next_group_event_timer()) — below 1.0 means shorter waits,
## customers arriving more often. Applied on top of that spawner's own
## reputation-based factor, and still clamped by its existing
## WALK_IN_INTERVAL_FLOOR_SECONDS/GROUP_EVENT_FLOOR_SECONDS floors so this
## can never make spawns instant.
@export var spawn_interval_multiplier: float = 1.0

## Multiplies how often an "Agentti" (LVV inspector) customer is picked by
## CustomerRegistry.get_random_customer_data()'s weighted selection — below
## 1.0 means fewer inspector visits. See Brewery.get_agentti_appearance_
## multiplier().
@export var agentti_appearance_multiplier: float = 1.0
## Same weighted-selection mechanism as agentti_appearance_multiplier,
## for "Mafioso" customers — above 1.0 means more of them. See Brewery.
## get_mafioso_appearance_multiplier().
@export var mafioso_appearance_multiplier: float = 1.0

## Chance (0.0-1.0) that a sale's tip is doubled — rolled in
## CustomerManager.process_auto_sale() right where tip income is applied.
## Neutral at 0.0, same "no sensible multiplicative stacking for a
## probability" reasoning as ingredient_refund_chance — summed by a plain
## loop, not combine_stacking(). See Brewery.get_tip_double_chance().
@export var tip_double_chance: float = 0.0

## Multiplies CustomerData.bar_fight_chance right before CustomerManager.
## process_auto_sale() rolls it — below 1.0 means fewer bar fights (the
## game's one existing "negative sale outcome" roll). See Brewery.
## get_bar_fight_chance_multiplier().
@export var bar_fight_chance_multiplier: float = 1.0

## Multiplies the listed style price BEFORE CustomerManager.process_auto_sale()
## feeds it into CustomerData.evaluate_brew_batch() — a normal walk-in
## counter sale getting a better price for the same beer, purely from
## strong branding. Deliberately separate from distribution_income_multiplier,
## which by design never touches a counter sale at all (see that field's own
## docstring) — this is the counter-sale counterpart. Above 1.0 means
## customers pay more per bottle; tip is computed off the same marked-up
## price afterward, so a strong brand's tips scale up with it too. See
## Brewery.get_counter_price_multiplier().
@export var counter_price_multiplier: float = 1.0

## Multiplies CustomerSpawner's group-visit spawn-interval roll only — NOT
## the solo walk-in roll, which stays governed purely by
## spawn_interval_multiplier above. Below 1.0 means crowds ("lauma" group
## visits) arrive more often, without touching how often a lone customer
## walks in. See Brewery.get_group_event_interval_multiplier().
@export var group_event_interval_multiplier: float = 1.0

## Flat extra strikes tolerated on top of Brewery.BUSTED_RAID_COUNT before
## the "busted" ending fires — see Brewery._check_for_lvv_raid() and
## get_extra_raid_tolerance(). Neutral at 0, summed by a plain loop across
## active_perks (same shape as ingredient_refund_chance above), not
## combine_stacking() — an extra-strikes count has no sensible
## multiplicative stacking mode either.
@export var extra_raid_strikes: int = 0

## Flat number of this brewery's own brew batches spared from confiscation
## each time an LVV raid fires — see Brewery._check_for_lvv_raid() and
## get_raid_hidden_batch_count(). Neutral at 0, same plain-sum-not-
## combine_stacking() reasoning as extra_raid_strikes above.
@export var raid_hidden_batch_count: int = 0

## Whether this perk's multiplier fields above (reputation_gain_
## multiplier, tip_income_multiplier, raid_threshold_multiplier,
## distribution_income_multiplier, ingredient_price_multiplier,
## brew_yield_multiplier, peak_speed_multiplier, decline_rate_multiplier,
## spawn_interval_multiplier, agentti_appearance_multiplier, mafioso_
## appearance_multiplier, bar_fight_chance_multiplier, counter_price_
## multiplier, group_event_interval_multiplier — NOT quality_bonus/
## ingredient_refund_chance/tip_double_chance, which are flat additions
## from the start) stack by ADDING their delta from 1.0 to
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
	if ingredient_price_multiplier != 1.0:
		lines.append(StringContainer.MODIFIER_INGREDIENT_PRICE_STAT_STRING % roundi((ingredient_price_multiplier - 1.0) * 100))
	if brew_yield_multiplier != 1.0:
		lines.append(StringContainer.PERK_YIELD_STAT_STRING % roundi((brew_yield_multiplier - 1.0) * 100))
	if ingredient_refund_chance != 0.0:
		lines.append(StringContainer.PERK_REFUND_CHANCE_STAT_STRING % roundi(ingredient_refund_chance * 100))
	if peak_speed_multiplier != 1.0:
		lines.append(StringContainer.PERK_PEAK_SPEED_STAT_STRING % roundi((peak_speed_multiplier - 1.0) * 100))
	if decline_rate_multiplier != 1.0:
		lines.append(StringContainer.PERK_DECLINE_RATE_STAT_STRING % roundi((decline_rate_multiplier - 1.0) * 100))
	if spawn_interval_multiplier != 1.0:
		lines.append(StringContainer.PERK_SPAWN_INTERVAL_STAT_STRING % roundi((spawn_interval_multiplier - 1.0) * 100))
	if agentti_appearance_multiplier != 1.0:
		lines.append(StringContainer.PERK_AGENTTI_APPEARANCE_STAT_STRING % roundi((agentti_appearance_multiplier - 1.0) * 100))
	if mafioso_appearance_multiplier != 1.0:
		lines.append(StringContainer.PERK_MAFIOSO_APPEARANCE_STAT_STRING % roundi((mafioso_appearance_multiplier - 1.0) * 100))
	if tip_double_chance != 0.0:
		lines.append(StringContainer.PERK_TIP_DOUBLE_CHANCE_STAT_STRING % roundi(tip_double_chance * 100))
	if bar_fight_chance_multiplier != 1.0:
		lines.append(StringContainer.PERK_BAR_FIGHT_CHANCE_STAT_STRING % roundi((bar_fight_chance_multiplier - 1.0) * 100))
	if counter_price_multiplier != 1.0:
		lines.append(StringContainer.PERK_COUNTER_PRICE_STAT_STRING % roundi((counter_price_multiplier - 1.0) * 100))
	if group_event_interval_multiplier != 1.0:
		lines.append(StringContainer.PERK_GROUP_EVENT_INTERVAL_STAT_STRING % roundi((group_event_interval_multiplier - 1.0) * 100))
	if extra_raid_strikes != 0:
		lines.append(StringContainer.PERK_EXTRA_RAID_STRIKES_STAT_STRING % extra_raid_strikes)
	if raid_hidden_batch_count != 0:
		lines.append(StringContainer.PERK_RAID_HIDDEN_BATCH_STAT_STRING % raid_hidden_batch_count)

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
