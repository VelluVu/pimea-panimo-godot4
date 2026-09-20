class_name CustomerData
extends Resource


const DEFAULT_TITLE: String = "Asiakas"
const DEFAULT_NAMES: Array[String] = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]

## Flat tip floor per quality point, so a clear overshoot is felt on cheap styles
## where the proportional tip rounds to nothing.
const MIN_TIP_PER_QUALITY_POINT : float = 1.0

@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var title: String = ""
@export var first_names: Array[String] = []
@export var min_quality: float = 0.5
## Tip generosity only: every customer pays the same fixed price for a style.
## See quality_tip_sensitivity.
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
## Shown when this customer leaves without buying: nothing in stock, or nothing that
## clears a strict requirement.
@export_multiline var dialogue_no_match: String = "Ei täällä ollu mitään minulle. Ehkä ensi kerralla."

## A hard gate, not a preference. A batch outside a set bound is invisible to this
## customer however good it is, see SaleProcessor.find_best_batch().
@export_group("Tiukat vaatimukset")
## -1 = no limit. E.g. 5.0 rejects anything under 5% ABV (see Barbaari).
@export var min_required_abv: float = -1.0
## -1 = no limit. E.g. 0.5 accepts only alcohol-free beer (see Zgen).
@export var max_required_abv: float = -1.0
## -1 = no limit. Rejects styles with a fixed price above this (see Opiskelija, a broke
## student who leaves if everything in stock is over budget).
@export var max_required_price: float = -1.0

@export_group("Tippaus")
## Tip per quality point above min_quality, scaled by budget_multiplier. Zero or below
## means this customer never tips (see Opiskelija).
@export var quality_tip_sensitivity: float = 0.3

@export_group("Reputation Changes")
@export var rep_bad_quality: int = -3
@export var rep_primary_style: int = 10
@export var rep_secondary_style: int = 0
@export var rep_wrong_style: int = -1
## Reputation per quality point above min_quality, and a penalty per point below it.
## A connoisseur can be given a higher value.
@export var quality_reputation_sensitivity: float = 4.0

@export_group("Risk Changes")
@export var risk_bad_quality: int = 1
@export var risk_primary_style: int = 3
@export var risk_secondary_style: int = 1
@export var risk_wrong_style: int = 2
## Risk reduction per quality point above min_quality, and extra risk below it. Scaled
## separately from reputation.
@export var quality_risk_sensitivity: float = 2.0

@export_group("Saatavuus")
@export var min_reputation_to_appear: int = 0
## -1 = no limit. Requires having brewed this style in ANY past run (see
## MetaProgressManager.has_style()), on top of min_reputation_to_appear. Gives a style with
## no other pull a reason to be brewed once.
@export var required_discovered_style: int = -1
## Empty = no limit. Requires AchievementManager.is_unlocked() for this id, permanent
## across runs like required_discovered_style (see Lähettirobotti).
@export var required_achievement_id: String = ""

@export_group("Erikoiskäytös")
@export var randomizes_preference: bool = false
@export var primary_match_risk_multiplier: float = 1.0
## Like the strict ABV gate, but preference-based: a batch matching neither the primary
## nor the secondary style is invisible to this customer (see Agentti, an undercover
## inspector who only wants today's cover-story styles).
@export var requires_preference_match: bool = false
## Per-customer override of CustomerManager.NO_MATCH_* for leaving via
## dialogue_no_match. Agentti zeroes them, since nothing was ever offered to him.
@export var no_match_reputation_penalty: int = CustomerManager.NO_MATCH_REPUTATION_PENALTY
@export var no_match_risk_penalty: int = CustomerManager.NO_MATCH_RISK_PENALTY
@export var min_bottles_per_visit: int = 1
@export var max_bottles_per_visit: int = 1
@export var bar_fight_chance: float = 0.0
@export var bar_fight_reputation_penalty: int = 0
@export var bar_fight_risk_penalty: int = 0
@export var bar_fight_max_bottles_broken: int = 0
## Incident narration, not something the customer says: shown as its own toast via
## BrewerySignals.bar_fight_triggered. Must contain one %d for the broken-bottle count.
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


## False when the batch fails a hard gate; such a batch is never considered, whatever
## its quality.
func meets_strict_requirements(beer_style: BeerStyle) -> bool:
	if min_required_abv >= 0.0 and beer_style.abv < min_required_abv:
		return false
	if max_required_abv >= 0.0 and beer_style.abv > max_required_abv:
		return false
	if max_required_price >= 0.0 and beer_style.fixed_price_per_bottle > max_required_price:
		return false
	if requires_preference_match and get_preference_score(beer_style.style) < 0.5:
		return false
	return true


## `styles` is the pool to draw from (the current run's active styles), passed
## in so this stays pure and unit-testable without any autoload.
func reroll_preference(styles : Array[BeerStyle]) -> void:
	if not randomizes_preference:
		return

	if styles.size() < 2:
		return

	var shuffled_styles := styles.duplicate()
	shuffled_styles.shuffle()

	primary_style = shuffled_styles[0].style
	secondary_style = shuffled_styles[1].style


## This customer's reaction to a batch, as a dictionary of CustomerManager.KEY_* values.
## The caller passes `style_base_price`, so no autoload is needed here. Every customer
## pays the same fixed price for a style: match and quality only move reputation and risk,
## plus a tip when quality exceeds this customer's own bar.
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

	# Quality effect on top of the branch: distance from this customer's min_quality, either
	# way. Zero at the bar, positive above it (extra reputation, less risk) and negative in
	# the bad-quality branch (the worse the miss, the harsher the penalty).
	var quality_margin : float = quality - min_quality
	rep_change += roundi(quality_margin * quality_reputation_sensitivity)

	var risk_adjustment : int = roundi(quality_margin * quality_risk_sensitivity)
	# Floor at 0 only for normally risky values, so quality can cancel a sale's risk but not
	# turn it into a reward. A deliberately negative flat risk (Zgen's alcohol-free favourites
	# de-risk the LVV meter) keeps working past 0.
	if avi_change > 0:
		avi_change = maxi(0, avi_change - risk_adjustment)
	else:
		avi_change -= risk_adjustment

	# Fixed price snapped to 10 cents (money is tracked to one decimal), floored at 0.1 so
	# a sale is never free.
	var income : float = maxf(0.1, snappedf(style_base_price, 0.1))

	# Tip only above the bar, scaled by budget_multiplier. MIN_TIP_PER_QUALITY_POINT is a
	# price-independent floor so an overshoot on a cheap style is not rounded away; the
	# proportional formula wins once income is high. Sensitivity <= 0 means no tip at all,
	# checked first so the flat floor cannot tip such a customer.
	var tip : float = 0.0
	if quality_margin > 0.0 and quality_tip_sensitivity > 0.0:
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