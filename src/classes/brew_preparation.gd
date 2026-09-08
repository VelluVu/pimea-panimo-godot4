class_name BrewPreparation
extends Resource


# Avain: int (Ingredient ID) -> Arvo: int (Määrä fyysisesti pöydällä juuri nyt)
@export var selected_contents: Dictionary = {}

# Avain: int (Ingredient ID) -> Arvo: int (Ladatun reseptin vaatima määrä), tyhjä jos reseptiä ei ole ladattu
@export var active_recipe_target: Dictionary = {}

func clear_preparation() -> void:
	selected_contents.clear()
	active_recipe_target.clear()


func has_item(ingredient_id: int, amount: int) -> bool:
	if not IngredientDatabase.has_item_by_id(ingredient_id):
		return false
	
	if not selected_contents.has(ingredient_id):
		return false
		
	return selected_contents[ingredient_id] >= amount


func add_to_table(ingredient_id: int, amount: int) -> void:
	if amount <= 0:
		return
	
	if not IngredientDatabase.has_item_by_id(ingredient_id):
		return
	
	if not selected_contents.has(ingredient_id):
		selected_contents[ingredient_id] = 0
		
	selected_contents[ingredient_id] += amount


func remove_from_table(ingredient_id: int, amount: int) -> int:
	if not has_item(ingredient_id, amount):
		return 0
	
	var on_table : int = selected_contents[ingredient_id]
	
	if on_table >= amount:
		selected_contents[ingredient_id] -= amount
		if selected_contents[ingredient_id] == 0:
			selected_contents.erase(ingredient_id)
		return amount
	else:
		selected_contents.erase(ingredient_id)
		return on_table
