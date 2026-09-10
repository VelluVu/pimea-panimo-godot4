class_name IngredientInventoryPanel
extends VBoxContainer

const AMOUNT_FORMAT : String = "%s: %s %s"

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
		new_label.mouse_filter = Control.MOUSE_FILTER_STOP
		new_label.modulate = ingredient.get_color()
		new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		new_label.add_theme_font_size_override("font_size", 16)
			
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
		var item : InventoryItem = null
		
		if inventory.items.has(ingredient.type) and inventory.items[ingredient.type].has(ingredient.id):
			item = inventory.items[ingredient.type][id]
		
		if item != null:
			var current_amount: int = inventory.items[ingredient.type][ingredient.id].amount
			
			label.text = AMOUNT_FORMAT % [ingredient.name, current_amount, ingredient.get_unit_string()]
			label.tooltip_text = ingredient.description + "\n" + ingredient.get_stat_string()
			label.visible = true
		else:
			label.visible = false
