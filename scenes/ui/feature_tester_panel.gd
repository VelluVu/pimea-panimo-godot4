class_name FeatureTesterPanel
extends Panel


const BUTTON_DOWN_SIGNAL_NAME : String = "button_down"

@onready var brew_lager_button : Button = $HBoxContainer/BrewLagerButton
@onready var test_special_customer_button : Button = $HBoxContainer/TestSpecialCustomerButton
@onready var test_normal_customer_button : Button = $HBoxContainer/TestNormalCustomerButton

var brewery : Brewery


func _ready() -> void:
	if not BrewEngine.DEVELOPER_MODE:
		hide()
		return
	
	brewery = BrewEngine.current_brewery
	
	brew_lager_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_brew_lager_button_down)
	test_special_customer_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_test_special_customer_button_down)
	test_normal_customer_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_test_normal_customer_button_down)


func _on_brew_lager_button_down() -> void:
	brewery.brew_preparation.add_to_table(100,3)
	brewery.brew_preparation.add_to_table(200,14)
	brewery.brew_preparation.add_to_table(301,1)
	brewery.start_brew()


func _on_test_special_customer_button_down() -> void:
	CustomerManager.spawn_special_customer()


func _on_test_normal_customer_button_down() -> void:
	CustomerManager.spawn_normal_customer()
