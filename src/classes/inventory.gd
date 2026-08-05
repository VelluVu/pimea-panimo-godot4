class_name Inventory
extends Resource


var items : Dictionary = {}


func add_amount(ingredient : IngredientData, amount : int) -> void:
	if not items.has(ingredient.type):
		items[ingredient.type] = {}
		
	if items[ingredient.type].has(ingredient.id):
		items[ingredient.type][ingredient.id].amount += amount
	else:
		var new_item := InventoryItem.new()
		new_item.ingredient_data = ingredient
		new_item.amount = amount
		items[ingredient.type][ingredient.id] = new_item


# Inventory.gd - ID-pohjaiset suojatut metodit
func get_item(ingredient : IngredientData) -> InventoryItem:
	if not has_item(ingredient):
		return null
	
	var item : InventoryItem = items[ingredient.type][ingredient.id]
	return item 


func withdraw_item(ingredient : IngredientData, amount : int) -> int:
	if amount <= 0:
		print(ErrorMessageContainer.WITHDRAW_INVALID_AMOUNT % [ErrorMessageContainer.INVENTORY_STRING, amount])
		return 0
	
	if not has_item(ingredient) or amount <= 0:
		return 0
		
	var item : InventoryItem = items[ingredient.type][ingredient.id]
	
	if item.amount < amount:
		print(ErrorMessageContainer.WITHDRAW_NO_STOCK % [ErrorMessageContainer.INVENTORY_STRING, ingredient.name])
		return 0 
		
	item.amount -= amount
	
	if item.amount == 0:
		items[ingredient.type].erase(ingredient.id)
		
	return amount


func has_item(ingredient : IngredientData) -> bool:
	if not items.has(ingredient.type) or not items[ingredient.type].has(ingredient.id):
		print(ErrorMessageContainer.INVALID_ID % [ErrorMessageContainer.INVENTORY_STRING , ingredient.id, ErrorMessageContainer.LIST_STRING])
		return false
	return true


func has_item_by_id(id: int) -> bool:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return false
	
	if not items.has(ingredient.type) or not items[ingredient.type].has(id):
		print(ErrorMessageContainer.INVALID_ID % [ErrorMessageContainer.INVENTORY_STRING , id, ErrorMessageContainer.LIST_STRING])
		return false
		
	return true


func has_item_by_type_and_id(type : IngredientData.IngredientType, id : int) -> bool:
	if not items.has(type) or not items[type].has(id):
		print(ErrorMessageContainer.INVALID_ID % [ErrorMessageContainer.INVENTORY_STRING , id, ErrorMessageContainer.LIST_STRING])
		return false
	return true


func get_item_by_type_and_id(type : IngredientData.IngredientType, id : int) -> InventoryItem:
	if not has_item_by_type_and_id(type, id):
		return null
	return items[type][id]


func get_item_by_id(id: int) -> InventoryItem:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return null
	
	if not has_item_by_type_and_id(ingredient.type, id):
		return null
	
	return items[ingredient.type][id]


func withdraw_item_by_id(id : int, amount : int) -> int:
	if amount <= 0:
		print(ErrorMessageContainer.WITHDRAW_INVALID_AMOUNT % [ErrorMessageContainer.INVENTORY_STRING, amount])
		return 0
	
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return 0
	
	var item : InventoryItem = get_item_by_type_and_id(ingredient.type, id)
	if item == null:
		return 0
	
	if item.amount < amount:
		print(ErrorMessageContainer.WITHDRAW_NO_STOCK % [ErrorMessageContainer.INVENTORY_STRING, ingredient.name])
		return 0
	
	item.amount -= amount
	
	if item.amount == 0:
		items[ingredient.type].erase(id)
		
	return amount
	


func add_amount_by_id(id: int, amount: int) -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return
	
	if not items.has(ingredient.type):
		items[ingredient.type] = {}
		
	if items[ingredient.type].has(id):
		items[ingredient.type][id].amount += amount
	else:
		var new_item := InventoryItem.new()
		new_item.ingredient_data = ingredient
		new_item.amount = amount
		items[ingredient.type][id] = new_item
