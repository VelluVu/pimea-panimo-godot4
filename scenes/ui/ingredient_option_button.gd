class_name IngredientOptionButton
extends OptionButton


@export var target_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT


func _ready() -> void:
	while not IngredientDatabase.is_loaded:
		await get_tree().process_frame # Odottaa yhden framen (ruudunpäivityksen)
		
	populate_ingredient_option_menu()


func populate_ingredient_option_menu() -> void:
	clear()
	
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]
		
		if ingredient.type == target_type:
			add_item(ingredient.name)
			var new_item_index = get_item_count() - 1
			set_item_id(new_item_index, ingredient.id)
			
	if get_item_count() > 0:
		select(0)
		item_selected.emit(0) 
