class_name SaleEvaluation
extends RefCounted

## A customer's reaction to one batch, as a dictionary of CustomerManager.KEY_* values.
## Every customer pays the same fixed price for a style: style match and quality only
## move reputation and risk, plus a chance of a tip when quality beats the customer's
## own bar and the beer is to their taste.

## A tip works like a crit: a small base chance (CustomerData.tip_base_chance), raised
## by quality above the customer's own bar, by how much they like the style and by perks
## (PerkStats.TIP_CHANCE). A beer that is not to their taste gets tried and left, no tip.
const DEFAULT_TIP_BASE_CHANCE : float = 0.1
const TIP_CHANCE_PER_MARGIN : float = 0.6
const FAVOURITE_TIP_CHANCE : float = 0.15
const SECOND_CHOICE_TIP_CHANCE : float = 0.05
const TIP_CHANCE_MAX : float = 0.9
## Quality above the bar counts up to this much, for the chance and the size alike, so a
## customer with a very low bar cannot turn any decent beer into a huge tip.
const TIP_MARGIN_MAX : float = 1.0
## A tip is this share of the price plus the quality margin, times the customer's
## sensitivity and budget: an expensive, well-made beer earns the biggest tips.
const TIP_BASE_SHARE : float = 0.5
## Caps the reputation a sale earns for quality above the bar. Uncapped, customers with
## a very low bar (Opiskelija, Raksamies) gave almost double reputation for any decent
## beer. Penalties stay uncapped.
const QUALITY_REPUTATION_BONUS_MAX : int = 2
## A connoisseur's (CustomerData.buys_below_bar) sale below their bar: at most this much
## reputation, no tip, and the grumble below instead of their usual line.
const BELOW_BAR_REPUTATION : int = -1
const BELOW_BAR_LINE : String = "Menee se, mutta odotin parempaa."
## What customers say about a soured batch they bought anyway.
const SOUR_REACTIONS : SourReactions = preload("res://src/resources/sour_reactions/sour_reactions.tres")


## `tip_roll` (0 to 1) decides whether this sale tips, see tip_chance().
static func evaluate(customer : CustomerData, batch : BrewBatch, style_base_price : float, tip_roll : float = randf(), tip_chance_bonus : float = 0.0) -> Dictionary:
	var quality : float = batch.current_quality
	var score : float = customer.get_batch_preference(batch)

	var reputation : int
	var risk : int
	var response : String
	var delighted : bool = false
	var below_bar : bool = quality < customer.min_quality
	if below_bar and not customer.buys_below_bar:
		reputation = customer.rep_bad_quality
		risk = customer.risk_bad_quality
		response = customer.dialogue_reject
	elif score >= 1.0:
		delighted = true
		reputation = customer.rep_primary_style
		risk = roundi(customer.risk_primary_style * customer.primary_match_risk_multiplier)
		response = customer.dialogue_success
	elif score >= 0.5:
		reputation = customer.rep_secondary_style
		risk = customer.risk_secondary_style
		response = customer.dialogue_fallback
	else:
		reputation = customer.rep_wrong_style
		risk = customer.risk_wrong_style
		response = customer.dialogue_wrong_style

	# Zero at the bar, positive above it, negative in the bad-quality branch.
	var quality_margin : float = quality - customer.min_quality
	# A beer they did not want earns nothing for being well made: the wrong style always
	# costs reputation, so serving one easy style to everyone does not pay.
	var suffix : String = ""
	if below_bar and customer.buys_below_bar:
		reputation = mini(reputation, BELOW_BAR_REPUTATION)
		delighted = false
		response = BELOW_BAR_LINE
		suffix = QualityWishText.reject_suffix(quality, customer.min_quality)
	elif score >= 0.5:
		reputation += quality_reputation(quality_margin, customer.quality_reputation_sensitivity)
	risk = risk_after_quality(risk, roundi(quality_margin * customer.quality_risk_sensitivity))
	var income : float = income_for(style_base_price)
	var tip : float = 0.0
	if tip_roll < tip_chance(customer.tip_base_chance, quality_margin, score, tip_chance_bonus):
		tip = tip_for(income, quality_margin, customer.quality_tip_sensitivity, customer.budget_multiplier)

	# A soured batch they still bought gets a word about the sourness; only a light
	# sour can still delight anyone.
	var sour_level : FermentationRules.SourLevel = batch.get_sour_level()
	if sour_level != FermentationRules.SourLevel.NONE and quality >= customer.min_quality:
		response = SOUR_REACTIONS.line_for(sour_level)
		if sour_level != FermentationRules.SourLevel.LIGHT:
			delighted = false

	if customer.minds_purity_law(batch):
		reputation = customer.rep_purity_law_broken
		tip = 0.0
		delighted = false
		response = customer.dialogue_purity_law_broken

	return {
		CustomerManager.KEY_INCOME: income,
		CustomerManager.KEY_TIP: tip,
		CustomerManager.KEY_REPUTATION: reputation,
		CustomerManager.KEY_RISK: risk,
		CustomerManager.KEY_RESPONSE: UiText.of(response) + suffix,
		CustomerManager.KEY_DELIGHTED: delighted,
	}


## Reputation (x) and risk (y) of refusing a batch below the bar: the flat bad-quality
## penalty, growing the further below the bar the batch is.
static func refusal(customer : CustomerData, quality : float) -> Vector2i:
	var quality_margin : float = quality - customer.min_quality
	return Vector2i(
		customer.rep_bad_quality + quality_reputation(quality_margin, customer.quality_reputation_sensitivity),
		risk_after_quality(customer.risk_bad_quality, roundi(quality_margin * customer.quality_risk_sensitivity)))


static func quality_reputation(quality_margin : float, sensitivity : float) -> int:
	return mini(roundi(quality_margin * sensitivity), QUALITY_REPUTATION_BONUS_MAX)


## Quality can cancel a sale's risk but not turn it into a reward. A deliberately
## negative flat risk (Zgen's alcohol-free favourites calm the LVV) keeps going past 0.
static func risk_after_quality(risk : int, adjustment : int) -> int:
	if risk > 0:
		return maxi(0, risk - adjustment)
	return risk - adjustment


## A sale's added risk scaled by `multiplier` (aging, perks). Risk is whole points and a
## sale adds only a few, so the fraction is rounded up with its own odds (`roll` 0 to 1):
## a small cut still counts on average. A negative risk is left alone.
static func discreet_risk(risk : int, multiplier : float, roll : float) -> int:
	if risk <= 0:
		return risk
	var scaled : float = risk * maxf(0.0, multiplier)
	var whole : int = floori(scaled)
	return whole + (1 if roll < scaled - whole else 0)


## The fixed price snapped to 10 cents, never free.
static func income_for(style_base_price : float) -> float:
	return maxf(0.1, snappedf(style_base_price, 0.1))


## Only above the bar and for beer to the customer's taste (`preference`, see
## CustomerData.get_batch_preference()). `bonus` is the perks' PerkStats.TIP_CHANCE.
static func tip_chance(base_chance : float, quality_margin : float, preference : float, bonus : float = 0.0) -> float:
	if quality_margin <= 0.0 or preference < 0.5:
		return 0.0
	var taste : float = FAVOURITE_TIP_CHANCE if preference >= 1.0 else SECOND_CHOICE_TIP_CHANCE
	var chance : float = base_chance + minf(quality_margin, TIP_MARGIN_MAX) * TIP_CHANCE_PER_MARGIN + taste + bonus
	return clampf(chance, 0.0, TIP_CHANCE_MAX)


## The tip per serving when the customer tips. Sensitivity <= 0 never tips.
static func tip_for(income : float, quality_margin : float, sensitivity : float, budget_multiplier : float) -> float:
	if quality_margin <= 0.0 or sensitivity <= 0.0:
		return 0.0
	var share : float = TIP_BASE_SHARE + minf(quality_margin, TIP_MARGIN_MAX)
	return maxf(0.0, snappedf(income * share * sensitivity * budget_multiplier, 0.1))
