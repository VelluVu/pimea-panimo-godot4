class_name IngredientOptionButton
extends OptionButton


@export var target_type: IngredientData.IngredientType = IngredientData.IngredientType.MALT


func _ready() -> void:
	populate_ingredient_option_menu()


func populate_ingredient_option_menu() -> void:
	clear()
	
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]
		
		if ingredient.type == target_type:
			add_item(ingredient.name)
			var new_item_index = get_item_count() - 1
			set_item_id(new_item_index, ingredient.id)
