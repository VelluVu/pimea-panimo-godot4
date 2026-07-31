#IngredientDatabase (autoload)
extends Node

static var database: Dictionary = {}
static var sorted_ids: Array[int] = []
var inventory: Inventory = null

static var is_loaded: bool = false


static func _static_init() -> void:
	print("[IngredientDatabase] Start recursive folder scan...")
	build_ingredient_database_recursive("res://src/resources/ingredients/")
	
	for id in database.keys():
		sorted_ids.append(id)
	sorted_ids.sort()
	
	is_loaded = true
	print("[IngredientDatabase] Database fully sorted! Total registered items: ", database.size())


static func build_ingredient_database_recursive(folder_path: String) -> void:
	var directory_items = ResourceLoader.list_directory(folder_path)
	
	for item in directory_items:
		if item.ends_with("/"):
			var sub_folder_path = folder_path.path_join(item)
			build_ingredient_database_recursive(sub_folder_path)
			
		elif item.ends_with(".tres"):
			var file_path = folder_path.path_join(item)
			var ingredient_res: IngredientData = load(file_path)
			
			if ingredient_res:
				if database.has(ingredient_res.id):
					printerr("VIRHE: ID ", ingredient_res.id, " on jo käytössä! Päällekkäisyys: ", ingredient_res.name)
				else:
					database[ingredient_res.id] = ingredient_res
					print("Tietokanta löysi alikansiosta: ", ingredient_res.name, " (ID: ", ingredient_res.id, ")")
