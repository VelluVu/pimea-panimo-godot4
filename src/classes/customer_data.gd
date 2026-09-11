class_name CustomerData
extends Resource


const DEFAULT_TITLE: String = "Asiakas"
const DEFAULT_NAMES: Array[String] = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]

@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var title: String = ""
@export var first_names: Array[String] = []
@export var min_quality: float = 0.5
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

@export_group("Price Multipliers")
@export var multiplier_bad_quality: float = 0.4
@export var multiplier_primary_style: float = 1.2
@export var multiplier_secondary_style: float = 0.9
@export var multiplier_wrong_style: float = 0.5

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


## style_base_price is resolved by the caller (BrewResolver.get_style_base_price,
## reached via BrewEngine.current_brewery in CustomerManager) rather than
## looked up here, so this stays pure per-CustomerData logic that doesn't
## reach into any autoload — see test_customer_data.gd's suite docstring.
func evaluate_brew_batch(batch: BrewBatch, style_base_price: float = 3.0) -> Dictionary:
	var style = batch.beer_style.style
	var quality = batch.current_quality
	var score = get_preference_score(style)
	
	var price_modifier = 1.0
	var rep_change = 0
	var avi_change = 1
	var response_text = ""
	
	if quality < min_quality:
		price_modifier = multiplier_bad_quality
		rep_change = rep_bad_quality
		avi_change = risk_bad_quality
		response_text = dialogue_reject
	elif score >= 1.0:
		price_modifier = multiplier_primary_style
		rep_change = rep_primary_style
		avi_change = roundi(risk_primary_style * primary_match_risk_multiplier)
		response_text = dialogue_success
	elif score >= 0.5:
		price_modifier = multiplier_secondary_style
		rep_change = rep_secondary_style
		avi_change = risk_secondary_style
		response_text = dialogue_fallback
	else:
		price_modifier = multiplier_wrong_style
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
	avi_change = maxi(0, avi_change - roundi(quality_margin * quality_risk_sensitivity))

	var income = roundi(1 * style_base_price * quality * budget_multiplier * price_modifier)
	
	return {
		CustomerManager.KEY_INCOME: income,
		CustomerManager.KEY_REPUTATION: rep_change,
		CustomerManager.KEY_RISK: avi_change,
		CustomerManager.KEY_RESPONSE: response_text
	}