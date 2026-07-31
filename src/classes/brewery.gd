class_name Brewery
extends Resource

@export var inventory : Inventory
@export var money: int = 100
@export var risk: int = 0
@export var reputation: int = 10
@export var brew_preparation : BrewPreparation


func _init() -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()


func _ready() -> void:
	GUISignals.add_ingredient_to_brew_preparation.connect(_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.connect(_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.connect(_buy_ingredient)
	GUISignals.sell_ingredient.connect(_sell_ingredient)
	GUISignals.start_brewing.connect(_start_brew)


func emit_initial_values() -> void:
	BrewerySignals.brewery_state_changed.emit(self)


func _add_ingredient_to_brew_preparation(ingredient_id : int, amount : int) -> void:
	if IngredientDatabase.database[ingredient_id] == null:
		print("ERROR INGREDIENT WITH ID %s IS NOT ADDED TO DATABASE", ingredient_id)
		return
	
	var ingredient: IngredientData = IngredientDatabase.database[ingredient_id]
	
	if not inventory.has_item(ingredient, amount):
		print("DEBUG: Not enough ingredients in inventory for ID: %s" % ingredient_id)
		return
	
	var final_amount : int = inventory.get_amount(ingredient, amount)
	#add to brew preparation ingredient list
	brew_preparation.add_to_table(ingredient_id, final_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _remove_ingredient_from_brew_preparation(ingredient_id : int, amount : int) -> void:
	if IngredientDatabase.database[ingredient_id] == null:
		print("ERROR INGREDIENT WITH ID %s IS NOT ADDED TO DATABASE", ingredient_id)
		return
	
	var ingredient: IngredientData = IngredientDatabase.database[ingredient_id]
	
	if not brew_preparation.has_item(ingredient, amount):
		print("DEBUG: Not enough ingredients in inventory for ID: %s" % ingredient_id)
		return
	
	var exact_amount : int = brew_preparation.remove_from_table(ingredient_id, amount)
	inventory.add_amount(ingredient, exact_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _buy_ingredient(ingredient_id : int, amount : int) -> void:
	if IngredientDatabase.database[ingredient_id] == null:
		print("Joo ei oo tämmösiä matskuja olemassa!")
		return
	
	var ingredient: IngredientData = IngredientDatabase.database[ingredient_id]
	var buy_price : int = roundi(ingredient.base_price * amount)
	
	if money < buy_price:
		print("Ei oo rahaa tarpeeksi!")
		return

	money -= buy_price
	inventory.add_amount(ingredient, amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _sell_ingredient(ingredient_id : int, amount : int) -> void:
	if IngredientDatabase.database[ingredient_id] == null:
		print("Joo ei oo tämmösiä matskuja olemassa!")
		return
		
	var ingredient: IngredientData = IngredientDatabase.database[ingredient_id]
	
	if not inventory.has_item(ingredient, amount):
		print("Joo ei oo tarpeeksi tämmösiä matskuja varastossa ID:llä: %s" % ingredient_id)
		return
	
	var final_amount : int = inventory.get_amount(ingredient, amount)
	var sell_price : int = roundi(final_amount * ingredient.base_price * 0.75)
	money += sell_price #ei saa ihan samaa hintaa takas millä joskus osti...
	print("Myit %s määrän rojuja ja saat %s takas" %final_amount, sell_price)
	BrewerySignals.brewery_state_changed.emit(self)


func _start_brew() -> void:
	print("brewery start_brew is not implemented")
	#check if have enough added ingredients in list
