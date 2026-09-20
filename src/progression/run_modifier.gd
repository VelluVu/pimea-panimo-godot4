class_name RunModifier
extends Resource

## Rolled once per run in Brewery._init() (see Brewery.run_modifier) and
## read at the handful of call sites that touch LVV raids and ingredient
## pricing — never mutates shared IngredientData/Brewery constants in
## place, since those are reused across runs.

@export var modifier_name: String = ""
@export var description: String = ""
## True on exactly one modifier resource (tavallinen_keikka.tres) — the
## neutral, all-multipliers-1.0 baseline. RunModifierRegistry.
## get_random_modifiers() guarantees this one a slot among the offered
## cards rather than leaving it to the same shuffle as every other
## modifier, so a player who doesn't want a run-altering condition always
## has that option on the table.
@export var is_default: bool = false

## Emoji placeholder shown on ModifierSelectWindow's cards until real icon
## art exists for each modifier — swap this for an @export var icon:
## Texture2D once art is ready, no other code should need to change.
@export var icon_placeholder: String = "🎲"

## Multiplies Brewery.LVV_RAID_THRESHOLD — see Brewery.get_effective_raid_threshold().
## Below 1.0 means raids trigger sooner (more dangerous); above 1.0 means later.
@export var lvv_threshold_multiplier: float = 1.0

## Multiplies IngredientData.base_price wherever it's read for a real
## transaction or cost preview (Brewery._on_buy_ingredient/_on_sell_ingredient,
## BrewResolver's cost-preview functions). Since beer sale prices are fixed
## per style (BeerStyle.fixed_price_per_bottle), a higher multiplier directly
## squeezes profit margin rather than just being flavor text.
@export var ingredient_price_multiplier: float = 1.0

## Same three fields as RunPerk (see its own docstring), added so a run's
## starting conditions can trade against quality/reputation/tip too, not
## just LVV risk vs. ingredient price — e.g. a modifier that boosts
## reputation gain but tightens the raid threshold, a genuinely different
## axis than every existing modifier's risk-vs-price shape. Folded into
## Brewery.get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier() alongside the accumulated perks — see those
## methods. Neutral defaults (0.0 / 1.0) keep every modifier that doesn't
## set these acting exactly as before.
@export var quality_bonus: float = 0.0
@export var reputation_gain_multiplier: float = 1.0
@export var tip_income_multiplier: float = 1.0


## Same purpose as RunPerk.get_stat_summary() — a short, signed stat line
## per non-neutral field, so ModifierSelectWindow's cards and
## RunEffectsWindow show the real percentages instead of only flavor text.
func get_stat_summary() -> String:
	var lines : PackedStringArray = []

	if lvv_threshold_multiplier != 1.0:
		lines.append(StringContainer.MODIFIER_RAID_THRESHOLD_STAT_STRING % roundi((lvv_threshold_multiplier - 1.0) * 100))
	if ingredient_price_multiplier != 1.0:
		lines.append(StringContainer.MODIFIER_INGREDIENT_PRICE_STAT_STRING % roundi((ingredient_price_multiplier - 1.0) * 100))
	if quality_bonus != 0.0:
		lines.append(StringContainer.PERK_QUALITY_STAT_STRING % roundi(quality_bonus * 100))
	if reputation_gain_multiplier != 1.0:
		lines.append(StringContainer.PERK_REPUTATION_STAT_STRING % roundi((reputation_gain_multiplier - 1.0) * 100))
	if tip_income_multiplier != 1.0:
		lines.append(StringContainer.PERK_TIP_STAT_STRING % roundi((tip_income_multiplier - 1.0) * 100))

	return "\n".join(lines)


## Net "harder than Tavallinen keikka" sum across every field's own harder/
## easier direction (lower lvv_threshold_multiplier, higher
## ingredient_price_multiplier, and lower quality_bonus/
## reputation_gain_multiplier/tip_income_multiplier all read as harder) —
## positive means net harder than baseline, negative means net easier, zero
## for the baseline itself. Not authored per-resource: it falls out of the
## same fields that already drive gameplay, so a new modifier's difficulty
## can never drift out of sync with what it actually does. Used both by
## RunModifierRegistry.get_run_start_modifiers() to bucket modifiers into a
## medium/hard split, and by LeaderboardManager.calculate_score() to weight
## the end-of-run score.
func get_difficulty_score() -> float:
	var score : float = 0.0
	score += 1.0 - lvv_threshold_multiplier
	score += ingredient_price_multiplier - 1.0
	score += -quality_bonus
	score += 1.0 - reputation_gain_multiplier
	score += 1.0 - tip_income_multiplier
	return score
