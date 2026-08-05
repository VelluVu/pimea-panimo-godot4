class_name IngredientInventoryPanel
extends VBoxContainer


@onready var ingredient_list_vbox = $IngredientInventoryScrollContainer/IngredientListVBox
var storage_labels: Dictionary = {} # Avain: int (ID) -> Arvo: Label


func _ready() -> void:
	_initialize_storage_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	_update_ingredient_list()


func _initialize_storage_nodes() -> void:
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]
		
		var new_label := Label.new()
		new_label.visible = false 
		new_label.modulate = ingredient.get_color()
			
		ingredient_list_vbox.add_child(new_label)
		storage_labels[id] = new_label 


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_ingredient_list()


func _update_ingredient_list() -> void:
	if BrewEngine.current_brewery == null:
		return
	
	var inventory : Inventory = BrewEngine.current_brewery.inventory
	
	for id in IngredientDatabase.sorted_ids:
		var ingredient : IngredientData = IngredientDatabase.database[id]
		var label: Label = storage_labels[id]
		var item : InventoryItem = inventory.get_item_by_type_and_id(ingredient.type, id)
		
		if item != null:
			var current_amount: int = inventory.items[ingredient.type][ingredient.id].amount
			
			label.text = ingredient.name + ": " + str(current_amount) + " " + ingredient.get_unit_string()
			label.visible = true
		else:
			label.visible = false
