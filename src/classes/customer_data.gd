class_name CustomerData
extends Resource


const DEFAULT_TITLE: String = "Asiakas"
const DEFAULT_NAMES: Array[String] = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]

## Flat EUR-per-full-quality-point floor under the proportional tip
## formula (see evaluate_brew_batch) — keeps a clear overshoot felt on
## cheap styles, where price*margin*sensitivity alone rounds to nothing.
const MIN_TIP_PER_QUALITY_POINT : float = 1.0

@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var title: String = ""
@export var first_names: Array[String] = []
@export var min_quality: float = 0.5
## No longer affects what this customer pays for a bottle — every customer
## pays the same fixed, style-based price (see evaluate_brew_batch). Now
## purely a tip-generosity trait: how big a tipper this customer is when
## the quality genuinely exceeds their expectations (see quality_tip_sensitivity).
@export var budget_multiplier: float = 1.0
@export var primary_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var secondary_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA

@export_group("Ulkoasu")
@export var sprite_frames: SpriteFrames = null
@export var skin_base_color: Color = Color(0.918, 0.831, 0.667)
@export var hair_base_color: Color = Color(0.722, 0.435, 0.314)
@export var clothes_base_color: Color = Color(0.0, 0.6, 0.859)
@export var shoes_base_color: Color = Color(0.451, 0.243, 0.224)
@export var randomize_skin: bool = true
@export var randomize_hair: bool = true
@export var randomize_clothes: bool = true
@export var randomize_shoes: bool = true

@export_group("Movement Physics")
@export var stair_step_duration: float = 0.3
@export var floor_walk_speed: float = 120.0

@export_group("Dialogues")
@export_multiline var dialogue_intro: String = "Moro. Oisko jotain juotavaa?"
@export_multiline var dialogue_success: String = "Kylläpä uppoo! Tässä rahat."
@export_multiline var dialogue_fallback: String = "No, tämäkin käy paremman puutteessa."
@export_multiline var dialogue_wrong_style: String = "Ei tää sitäkään ollu, mut menköön..."
@export_multiline var dialogue_reject: String = "Mitä helvettiä sä mulle myyt? Pitää tunkkis."
## Shown when this customer leaves WITHOUT buying anything — either there's
## no beer in stock at all, or (see Tiukat vaatimukset below) nothing on
## offer clears a hard requirement they won't compromise on.
@export_multiline var dialogue_no_match: String = "Ei täällä ollu mitään minulle. Ehkä ensi kerralla."

## A hard gate, not a preference — unlike primary/secondary_style (which by
## default only affect reputation/risk/dialogue, never whether a sale
## happens at all — see requires_preference_match below for the opt-in
## exception), a customer with either bound set refuses to buy ANY batch
## outside it, no matter how good the quality or how badly the brewery
## needs the sale. Checked in CustomerManager._find_best_batch before
## scoring, so an out-of-range batch isn't just deprioritized, it's
## invisible to this customer.
@export_group("Tiukat vaatimukset")
## -1 = ei rajoitusta. Esim. 5.0 hylkää kaiken alle 5% ABV:n (ks. Barbaari).
@export var min_required_abv: float = -1.0
## -1 = ei rajoitusta. Esim. 0.5 hyväksyy vain alkoholittomat (ks. Zgen).
@export var max_required_abv: float = -1.0

@export_group("Tippaus")
## Extra money on top of the fixed price, per quality point above
## min_quality (zero or below it — no tip for merely meeting expectations,
## let alone missing them). Scaled by budget_multiplier, so a big-spender
## customer's tip is more generous than a broke one's for the same
## over-delivery. See evaluate_brew_batch's quality_margin.
@export var quality_tip_sensitivity: float = 0.3

@export_group("Reputation Changes")
@export var rep_bad_quality: int = -3
@export var rep_primary_style: int = 10
@export var rep_secondary_style: int = 0
@export var rep_wrong_style: int = -1
## Extra reputation per quality point above this customer's own min_quality
## bar (and extra penalty per point below it) — see evaluate_brew_batch's
## quality_margin. A connoisseur-type customer can be given a higher value
## here to react more strongly to a masterfully brewed batch.
@export var quality_reputation_sensitivity: float = 4.0

@export_group("Risk Changes")
@export var risk_bad_quality: int = 1
@export var risk_primary_style: int = 3
@export var risk_secondary_style: int = 1
@export var risk_wrong_style: int = 2
## Risk reduction per quality point above min_quality (and extra risk per
## point below it) — same quality_margin as quality_reputation_sensitivity,
## just scaled separately since risk and reputation shouldn't necessarily
## move at the same rate.
@export var quality_risk_sensitivity: float = 2.0

@export_group("Saatavuus")
@export var min_reputation_to_appear: int = 0

@export_group("Erikoiskäytös")
@export var randomizes_preference: bool = false
@export var primary_match_risk_multiplier: float = 1.0
## Same hard-gate mechanism as min_required_abv/max_required_abv above, but
## preference-based instead of ABV-based: when true, a batch that matches
## neither this customer's primary nor secondary style (get_preference_score
## == 0.0) is invisible to them, exactly as if the brewery had nothing in
## stock at all — they never settle for an unrelated style. See Agentti: an
## undercover LVV inspector only interested in styles that match today's
## cover story, not just anything on tap.
@export var requires_preference_match: bool = false
## Per-customer override for CustomerManager's NO_MATCH_REPUTATION_PENALTY/
## NO_MATCH_RISK_PENALTY, applied whenever this customer leaves via
## dialogue_no_match (empty inventory, a failed Tiukat vaatimukset check, or
## requires_preference_match above). Defaults to the same values every
## other customer pays for being turned away empty-handed; Agentti zeroes
## these out since, from the brewery's perspective, nothing was ever
## actually offered to him.
@export var no_match_reputation_penalty: int = CustomerManager.NO_MATCH_REPUTATION_PENALTY
@export var no_match_risk_penalty: int = CustomerManager.NO_MATCH_RISK_PENALTY
@export var min_bottles_per_visit: int = 1
@export var max_bottles_per_visit: int = 1
@export var bar_fight_chance: float = 0.0
@export var bar_fight_reputation_penalty: int = 0
@export var bar_fight_risk_penalty: int = 0
@export var bar_fight_max_bottles_broken: int = 0
@export_multiline var dialogue_bar_fight: String = ""


func generate_display_name() -> String:
	if title == "" or first_names.is_empty():
		return DEFAULT_TITLE + " " + DEFAULT_NAMES.pick_random()
	return title + " " + first_names.pick_random()


func get_preference_score(style: BeerStyle.Style) -> float:
	if style == primary_style:
		return 1.0
	elif style == secondary_style:
		return 0.5
	return 0.0


## See min_required_abv/max_required_abv's docstring — a batch that fails
## this is never considered for this customer at all, regardless of style
## match or quality.
func meets_strict_requirements(beer_style: BeerStyle) -> bool:
	if min_required_abv >= 0.0 and beer_style.abv < min_required_abv:
		return false
	if max_required_abv >= 0.0 and beer_style.abv > max_required_abv:
		return false
	if requires_preference_match and get_preference_score(beer_style.style) < 0.5:
		return false
	return true


func reroll_preference() -> void:
	if not randomizes_preference:
		return

	if BrewEngine.current_brewery == null:
		return

	var styles : Array[BeerStyle] = BrewEngine.current_brewery.resolver.active_styles
	if styles.size() < 2:
		return

	var shuffled_styles := styles.duplicate()
	shuffled_styles.shuffle()

	primary_style = shuffled_styles[0].style
	secondary_style = shuffled_styles[1].style


## style_base_price is resolved by the caller (BrewResolver.get_price_breakdown,
## reached via BrewEngine.current_brewery in CustomerManager) rather than
## looked up here, so this stays pure per-CustomerData logic that doesn't
## reach into any autoload — see test_customer_data.gd's suite docstring.
##
## The price itself never moves — every customer pays the same fixed,
## style-based price for the same beer, full stop. Style match and quality
## only affect reputation/risk (as before) and, new, a tip: extra money on
## top, but only when quality genuinely exceeds this customer's own bar
## (quality_margin > 0) — meeting expectations earns no bonus, missing them
## earns no discount either.
func evaluate_brew_batch(batch: BrewBatch, style_base_price: float = 3.0) -> Dictionary:
	var style = batch.beer_style.style
	var quality = batch.current_quality
	var score = get_preference_score(style)

	var rep_change = 0
	var avi_change = 1
	var response_text = ""

	if quality < min_quality:
		rep_change = rep_bad_quality
		avi_change = risk_bad_quality
		response_text = dialogue_reject
	elif score >= 1.0:
		rep_change = rep_primary_style
		avi_change = roundi(risk_primary_style * primary_match_risk_multiplier)
		response_text = dialogue_success
	elif score >= 0.5:
		rep_change = rep_secondary_style
		avi_change = risk_secondary_style
		response_text = dialogue_fallback
	else:
		rep_change = rep_wrong_style
		avi_change = risk_wrong_style
		response_text = dialogue_wrong_style

	# Continuous quality effect on top of the branch above: distance from
	# THIS customer's own min_quality bar, in either direction. Zero right
	# at the bar (matches the old all-or-nothing behavior exactly at the
	# threshold), positive above it in every non-bad-quality branch (a
	# masterful batch earns extra reputation and a bit less risk even from
	# a picky customer), negative in the bad-quality branch (the worse the
	# miss, the harsher the penalty, instead of a single flat number).
	var quality_margin : float = quality - min_quality
	rep_change += roundi(quality_margin * quality_reputation_sensitivity)

	var risk_adjustment : int = roundi(quality_margin * quality_risk_sensitivity)
	# The floor-at-0 only applies starting from a normally-risky flat value
	# (risk_bad_quality/risk_primary_style/etc default positive) so quality
	# can cancel a sale's own risk out but never flip it into a reward. A
	# customer deliberately given a NEGATIVE flat risk (e.g. Zgen's
	# risk_primary_style/risk_secondary_style — selling them their
	# alcohol-free favorite is meant to actively de-risk the LVV meter, see
	# max_required_abv's docstring) must keep working past 0 instead of
	# being floored right back to it.
	if avi_change > 0:
		avi_change = maxi(0, avi_change - risk_adjustment)
	else:
		avi_change -= risk_adjustment

	# Fixed price, snapped to the nearest 10 cents (money is tracked to one
	# decimal, not whole euros — see Brewery.money) and floored at 0.1 so a
	# sale never reads as a broken free/zero-cost transaction.
	var income : float = maxf(0.1, snappedf(style_base_price, 0.1))

	# Tip only fires above the bar (quality_margin > 0) — see the function
	# docstring. Scaled by budget_multiplier so a big-spender customer tips
	# more generously than a broke one for the same over-delivery.
	#
	# Pure income*margin*sensitivity rounds down to 0 on cheap styles even
	# at a clearly-exceeds margin (e.g. a 1 EUR Kotikalja at margin 0.5
	# gives 0.15) — the mechanic would never be felt on early-game beers.
	# MIN_TIP_PER_QUALITY_POINT is a price-independent floor so a real
	# overshoot is never silently invisible; the proportional formula
	# still wins (and keeps scaling with price) once income is high enough
	# for it to exceed the flat floor.
	var tip : float = 0.0
	if quality_margin > 0.0:
		var proportional_tip : float = income * quality_margin * quality_tip_sensitivity
		var floor_tip : float = quality_margin * MIN_TIP_PER_QUALITY_POINT
		tip = maxf(0.0, snappedf(max(proportional_tip, floor_tip) * budget_multiplier, 0.1))

	return {
		CustomerManager.KEY_INCOME: income,
		CustomerManager.KEY_TIP: tip,
		CustomerManager.KEY_REPUTATION: rep_change,
		CustomerManager.KEY_RISK: avi_change,
		CustomerManager.KEY_RESPONSE: response_text
	}