class_name CustomerData
extends Resource


@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var min_quality: float = 0.5
@export var budget_multiplier: float = 1.0
@export var primary_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var secondary_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA

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

@export_group("Risk Changes")
@export var risk_bad_quality: int = 1
@export var risk_primary_style: int = 3
@export var risk_secondary_style: int = 1
@export var risk_wrong_style: int = 2


func get_preference_score(style: BeerStyle.Style) -> float:
	if style == primary_style:
		return 1.0
	elif style == secondary_style:
		return 0.5
	return 0.0


func evaluate_brew_batch(batch: BrewBatch) -> Dictionary:
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
		avi_change = risk_primary_style
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
		
	var style_base_price = 3.0
	if "base_price" in batch.beer_style:
		style_base_price = batch.beer_style.base_price
		
	var income = roundi(1 * style_base_price * quality * budget_multiplier * price_modifier)
	
	return {
		CustomerManager.KEY_INCOME: income,
		CustomerManager.KEY_REPUTATION: rep_change,
		CustomerManager.KEY_RISK: avi_change,
		CustomerManager.KEY_RESPONSE: response_text
	}