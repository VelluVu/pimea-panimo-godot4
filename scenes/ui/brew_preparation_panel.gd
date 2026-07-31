class_name BrewPreparationPanel
extends PanelContainer


@onready var table_list_vbox : VBoxContainer = $TableScrollContainer/IngredientListVBox

var table_labels: Dictionary = {} # Key: int (ID) -> Value: Label


func _ready() -> void:
	_initialize_table_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	_update_table_list_ui()


func _initialize_table_nodes() -> void:
	for id in IngredientDatabase.sorted_ids:
		var new_label := Label.new()
		new_label.visible = false # Aluksi piilossa, koska pöytä on tyhjä
		table_list_vbox.add_child(new_label)
		table_labels[id] = new_label


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_update_table_list_ui()


func _update_table_list_ui() -> void:
	if BrewEngine.current_brewery == null:
		return
	
	var prep_contents : Dictionary = BrewEngine.current_brewery.brew_preparation.selected_contents
	
	for id in IngredientDatabase.sorted_ids:
		
		var ingredient: IngredientData = IngredientDatabase.database[id]
		var label: Label = table_labels[id]
		
		if prep_contents.has(id) and prep_contents[id] > 0:
			var amount: int = prep_contents[id]
			
			label.text = ingredient.name + ": " + str(amount) + " " + ingredient.get_unit_string()
			label.modulate = ingredient.get_color()
			label.visible = true
		else:
			label.visible = false
