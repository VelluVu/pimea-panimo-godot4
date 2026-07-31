class_name Inventory
extends Resource


var items : Dictionary = {}


func add_amount(ingredient_data : IngredientData, amount : int) -> void:
	if not ingredient_data:
		return
		
	if not items.has(ingredient_data.type):
		items[ingredient_data.type] = {}
	
	if items[ingredient_data.type].has(ingredient_data.id):
		items[ingredient_data.type][ingredient_data.id].amount += amount
	else:
		var new_item := InventoryItem.new()
		new_item.ingredient_data = ingredient_data
		new_item.amount = amount
		
		items[ingredient_data.type][ingredient_data.id] = new_item


func get_amount(ingredient_data : IngredientData, amount : int) -> int:
	if not ingredient_data:
		return 0
		
	if not items.has(ingredient_data.type) or not items[ingredient_data.type].has(ingredient_data.id):
		return 0
	
	var stock: int = items[ingredient_data.type][ingredient_data.id].amount
	
	if stock >= amount:
		items[ingredient_data.type][ingredient_data.id].amount -= amount
		
		if items[ingredient_data.type][ingredient_data.id].amount <= 0:
			items[ingredient_data.type].erase(ingredient_data.id)
			
		return amount
	else:
		return 0


func has_item(ingredient_data: IngredientData, amount: int) -> bool:
	if not ingredient_data:
		return false
	
	if not items.has(ingredient_data.type):
		return false
	
	if not items[ingredient_data.type].has(ingredient_data.id):
		return false
	
	return items[ingredient_data.type][ingredient_data.id].amount >= amount
