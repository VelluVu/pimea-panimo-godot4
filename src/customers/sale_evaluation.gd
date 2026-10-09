class_name SaleEvaluation
extends RefCounted

## A customer's reaction to one batch, as a dictionary of CustomerManager.KEY_* values.
## Every customer pays the same fixed price for a style: style match and quality only
## move reputation and risk, plus a tip when quality beats the customer's own bar.

## Flat tip floor per quality point, so a clear overshoot is felt on cheap styles
## where the proportional tip rounds to nothing.
const MIN_TIP_PER_QUALITY_POINT : float = 1.0
## Caps the reputation a sale earns for quality above the bar. Uncapped, customers with
## a very low bar (Opiskelija, Raksamies) gave almost double reputation for any decent
## beer. Penalties stay uncapped.
const QUALITY_REPUTATION_BONUS_MAX : int = 2


static func evaluate(customer : CustomerData, batch : BrewBatch, style_base_price : float) -> Dictionary:
	var quality : float = batch.current_quality
	var score : float = customer.get_preference_score(batch.beer_style.style)

	var reputation : int
	var risk : int
	var response : String
	var delighted : bool = false
	if quality < customer.min_quality:
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
	reputation += quality_reputation(quality_margin, customer.quality_reputation_sensitivity)
	risk = risk_after_quality(risk, roundi(quality_margin * customer.quality_risk_sensitivity))
	var income : float = income_for(style_base_price)
	var tip : float = tip_for(income, quality_margin, customer.quality_tip_sensitivity, customer.budget_multiplier)

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
		CustomerManager.KEY_RESPONSE: UiText.of(response),
		CustomerManager.KEY_DELIGHTED: delighted,
	}


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


## Only above the bar. The flat floor keeps an overshoot on a cheap style from rounding
## away; the proportional tip wins once the price is high. Sensitivity <= 0 never tips.
static func tip_for(income : float, quality_margin : float, sensitivity : float, budget_multiplier : float) -> float:
	if quality_margin <= 0.0 or sensitivity <= 0.0:
		return 0.0
	var proportional_tip : float = income * quality_margin * sensitivity
	var floor_tip : float = quality_margin * MIN_TIP_PER_QUALITY_POINT
	return maxf(0.0, snappedf(maxf(proportional_tip, floor_tip) * budget_multiplier, 0.1))
