class_name FeatureTesterPanel
extends Panel


const BUTTON_DOWN_SIGNAL_NAME : String = "button_down"
const RANDOM_CUSTOMER_LABEL : String = "Satunnainen"

@onready var brew_lager_button : Button = $HBoxContainer/BrewLagerButton
@onready var test_special_customer_button : Button = $HBoxContainer/TestSpecialCustomerButton
@onready var customer_option_button : OptionButton = $HBoxContainer/CustomerOptionButton
@onready var test_normal_customer_button : Button = $HBoxContainer/TestNormalCustomerButton
@onready var test_avi_raid_button : Button = $HBoxContainer/TestAviRaidButton

var brewery : Brewery


func _ready() -> void:
	if not BrewEngine.DEVELOPER_MODE:
		hide()
		return
	
	brewery = BrewEngine.current_brewery

	_populate_customer_option_button()

	brew_lager_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_brew_lager_button_down)
	test_special_customer_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_test_special_customer_button_down)
	test_normal_customer_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_test_normal_customer_button_down)
	test_avi_raid_button.connect(BUTTON_DOWN_SIGNAL_NAME, _on_test_avi_raid_button_down)


func _populate_customer_option_button() -> void:
	customer_option_button.clear()
	customer_option_button.add_item(RANDOM_CUSTOMER_LABEL)
	customer_option_button.set_item_metadata(0, null)

	for customer_data in CustomerRegistry.customer_pool:
		var label = customer_data.resource_path.get_file().get_basename().capitalize()
		customer_option_button.add_item(label)
		customer_option_button.set_item_metadata(customer_option_button.item_count - 1, customer_data)


func _on_brew_lager_button_down() -> void:
	brewery.brew_preparation.add_to_table(100,3)
	brewery.brew_preparation.add_to_table(200,14)
	brewery.brew_preparation.add_to_table(301,1)
	brewery.start_brew()


func _on_test_special_customer_button_down() -> void:
	SpecialEventManager.spawn_special_customer()


func _on_test_normal_customer_button_down() -> void:
	var forced_data : CustomerData = customer_option_button.get_item_metadata(customer_option_button.selected)
	CustomerManager.spawn_normal_customer(forced_data)


func _on_test_avi_raid_button_down() -> void:
	brewery.add_risk(Brewery.AVI_RAID_THRESHOLD)
