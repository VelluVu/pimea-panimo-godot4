class_name TopPanelResources
extends HBoxContainer


const DAY_STRING : String = "Päivä: %s"

@onready var money_label : Label = $MoneyLabel
@onready var reputation_label : Label = $ReputationLabel
@onready var risk_label : Label = $RiskLabel
@onready var day_label : Label = $DayLabel
var last_money: int = -1
var last_reputation : int = -1
var last_risk: int = -1

func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	
	if BrewEngine.current_brewery != null:
		BrewEngine.current_brewery.emit_initial_values()


func _on_day_changed(new_day: int) -> void:
	_update_day_display(new_day)


func _update_day_display(day_num: int) -> void:
	if day_label:
		day_label.text = DAY_STRING % str(day_num)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	var new_money: int = brewery.money
	
	if last_money != -1:
		var change = new_money - last_money
		if change != 0:
			_create_popup_effect(money_label, change, " €", false)
			
	money_label.text = str(new_money) + " €"
	last_money = new_money
	
	var new_reputation : int = brewery.reputation
	
	if last_reputation != -1:
		var change = new_reputation - last_reputation
		if change != 0:
			_create_popup_effect(reputation_label, change, " €", false)
	
	reputation_label.text = "Maine: " + str(new_reputation)
	last_reputation = new_reputation
	
	var new_risk: int = brewery.risk
	if last_risk != -1:
		var change = new_risk - last_risk
		if change != 0:
			_create_popup_effect(risk_label, change, "%", true)
			
	risk_label.text = "AVI Riski: " + str(new_risk) + "%"
	last_risk = new_risk


func _create_popup_effect(target_label: Label, amount: int, suffix: String, is_risk: bool) -> void:
	var popup := Label.new()
	
	if amount > 0:
		popup.text = "+" + str(amount) + suffix
		popup.modulate = Color.RED if is_risk else Color.GREEN
	else:
		popup.text = str(amount) + suffix
		popup.modulate = Color.GREEN if is_risk else Color.RED
		
	target_label.add_child(popup)
	popup.position = Vector2(80, 0)
	
	var tween := create_tween().set_parallel(true)
	var target_pos := popup.position + Vector2(0, -35)
	var target_color := popup.modulate
	target_color.a = 0.0
	
	tween.tween_property(popup, "position", target_pos, 1.0)
	tween.tween_property(popup, "modulate", target_color, 1.0)
	
	tween.chain().tween_callback(popup.queue_free)
