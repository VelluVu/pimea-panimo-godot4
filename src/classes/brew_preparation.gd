class_name BrewPreparation
extends Resource


# Avain: int (Ingredient ID) -> Arvo: int (Määrä fyysisesti pöydällä juuri nyt)
@export var selected_contents: Dictionary = {}

func clear_preparation() -> void:
	selected_contents.clear()

# Lisää ainetta pöydälle
func add_to_table(ingredient_id: int, amount: int) -> void:
	if not selected_contents.has(ingredient_id):
		selected_contents[ingredient_id] = 0
	selected_contents[ingredient_id] += amount

# Vähentää ainetta pöydältä ja poistaa avaimen jos määrä menee nollaan
func remove_from_table(ingredient_id: int, amount: int) -> int:
	if not selected_contents.has(ingredient_id):
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
