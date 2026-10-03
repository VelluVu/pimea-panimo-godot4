#IngredientDatabase (autoload)
extends Node

static var database: Dictionary = {}
static var sorted_ids: Array[int] = []
var inventory: Inventory = null

static var is_loaded: bool = false


static func _static_init() -> void:
	print(StringContainer.FOLDER_SCAN_MESSAGE)
	build_ingredient_database_recursive(StringContainer.PATH_TO_INGREDIENTS)
	
	for id in database.keys():
		sorted_ids.append(id)
	sorted_ids.sort()
	
	is_loaded = true
	print(StringContainer.FOLDER_SCAN_COMPLETE_MESSAGE, database.size())


static func build_ingredient_database_recursive(folder_path: String) -> void:
	var directory_items: PackedStringArray = ResourceLoader.list_directory(folder_path)
	
	for item: String in directory_items:
		if item.ends_with(StringContainer.SLASH):
			var sub_folder_path: String = folder_path.path_join(item)
			build_ingredient_database_recursive(sub_folder_path)
			
		elif item.ends_with(StringContainer.RESOURCE_END):
			var file_path: String = folder_path.path_join(item)
			var raw_res: IngredientData = load(file_path)
			
			if raw_res:
				var final_res: IngredientData = raw_res
				var path_lower := file_path.to_lower()
				
				if path_lower.contains("/malts/") and not (raw_res is MaltData):
					var corrected_malt := MaltData.new()
					_copy_base_fields(raw_res, corrected_malt)
					corrected_malt.type = IngredientData.IngredientType.MALT
					if "ebc" in raw_res: corrected_malt.ebc = raw_res.get("ebc")
					final_res = corrected_malt
		
				elif path_lower.contains("/hops/") and not (raw_res is HopData):
					var corrected_hop := HopData.new()
					_copy_base_fields(raw_res, corrected_hop)
					corrected_hop.type = IngredientData.IngredientType.HOP
					if "alpha_acids" in raw_res: corrected_hop.alpha_acids = raw_res.get("alpha_acids")
					final_res = corrected_hop
		
				elif path_lower.contains("/yeasts/") and not (raw_res is YeastData):
					var corrected_yeast := YeastData.new()
					_copy_base_fields(raw_res, corrected_yeast)
					corrected_yeast.type = IngredientData.IngredientType.YEAST
					final_res = corrected_yeast
				
				if database.has(final_res.id):
					printerr(StringContainer.DATABASE_DUBLICATE_KEY_ERROR % [final_res.id, final_res.name])
				else:
					database[final_res.id] = final_res
					print(StringContainer.DATABASE_FOUND_DATA_MESSAGE % [final_res.name, final_res.id])


static func _copy_base_fields(source: IngredientData, target: IngredientData) -> void:
	target.id = source.id
	target.name = source.name
	target.description = source.description
	target.base_price = source.base_price
	target.take_over_path(source.resource_path)


## For lists the player reads: grouped by type (malts, hops, yeasts, spices), then id.
## Juniper keeps its old hop id 212 but belongs with the spices. sorted_ids stays the
## search order, since RecipeSearch breaks ties by it.
func display_ids() -> Array[int]:
	var ids : Array[int] = sorted_ids.duplicate()
	ids.sort_custom(func(a : int, b : int) -> bool:
		var type_a : int = database[a].type
		var type_b : int = database[b].type
		return type_a < type_b or (type_a == type_b and a < b))
	return ids


func has_item_by_id(id : int) -> bool:
	if not database.has(id):
		print(StringContainer.INVALID_ID_ERROR % [StringContainer.DATABASE_STRING, id, StringContainer.LIST_STRING])
		return false
	return true


func get_item_by_id(id : int) -> IngredientData:
	if not has_item_by_id(id):
		return null
	
	return database[id]
