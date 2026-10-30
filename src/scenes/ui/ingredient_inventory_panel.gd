class_name IngredientInventoryPanel
extends VBoxContainer

const AMOUNT_FORMAT : String = "%s: %s %s"
## An empty list said nothing, like a broken window; the keg tab already says why.
const EMPTY_TEXT : String = "Varasto on tyhjä. Raaka-aineet ostetaan kaupasta."
const EMPTY_TEXT_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches BeerBatchPanel.EMPTY_INVENTORY_COLOR

@onready var ingredient_list_vbox: VBoxContainer = $IngredientInventoryScrollContainer/IngredientListVBox
var storage_labels: Dictionary = {} # ingredient id -> Label
var _empty_label : Label


func _ready() -> void:
	_initialize_storage_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	_update_ingredient_list()


func _initialize_storage_nodes() -> void:
	_empty_label = Label.new()
	_empty_label.text = EMPTY_TEXT
	_empty_label.modulate = EMPTY_TEXT_COLOR
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ingredient_list_vbox.add_child(_empty_label)
	for id in IngredientDatabase.display_ids():
		var ingredient: IngredientData = IngredientDatabase.database[id]
		
		var new_label := TooltipLabel.new()
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
	var any_shown : bool = false

	for id in IngredientDatabase.display_ids():
		var ingredient : IngredientData = IngredientDatabase.database[id]
		var label: Label = storage_labels[id]
		var item : InventoryItem = null
		
		if inventory.items.has(ingredient.type) and inventory.items[ingredient.type].has(ingredient.id):
			item = inventory.items[ingredient.type][id]
		
		if item != null:
			var current_amount: int = inventory.items[ingredient.type][ingredient.id].amount
			
			label.text = AMOUNT_FORMAT % [tr(ingredient.name), ingredient.amount_text(current_amount), ingredient.get_unit_string()]
			label.tooltip_text = ingredient.get_tooltip_text()
			label.visible = true
			any_shown = true
		else:
			label.visible = false
	_empty_label.visible = not any_shown
