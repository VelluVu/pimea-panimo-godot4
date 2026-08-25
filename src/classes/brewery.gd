class_name Brewery
extends Resource


@export var inventory : Inventory
@export var money: int = 100
@export var risk: int = 0
@export var reputation: int = 10
@export var brew_preparation : BrewPreparation
var resolver : BrewResolver = null


func _init() -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()
	resolver = BrewResolver.new()
	resolver._ready()


func _ready() -> void:
	GUISignals.add_ingredient_to_brew_preparation.connect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.connect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.connect(_on_buy_ingredient)
	GUISignals.sell_ingredient.connect(_on_sell_ingredient)
	GUISignals.start_brewing.connect(_on_start_brew)


func emit_initial_values() -> void:
	BrewerySignals.brewery_state_changed.emit(self)


func _on_add_ingredient_to_brew_preparation(ingredient_id : int, amount : int) -> void:
	var final_amount : int =  inventory.withdraw_item_by_id(ingredient_id, amount)
	
	if final_amount <= 0:
		return
	
	brew_preparation.add_to_table(ingredient_id, final_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _on_remove_ingredient_from_brew_preparation(ingredient_id : int, amount : int) -> void:
	var exact_amount : int = brew_preparation.remove_from_table(ingredient_id, amount)
	inventory.add_amount_by_id(ingredient_id, exact_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _on_buy_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return
	
	var buy_price : int = roundi(ingredient.base_price * amount)
	
	if money < buy_price:
		print(StringContainer.RESOURCE_ERROR % [money, buy_price, StringContainer.MONEY_STRING])
		return

	money -= buy_price
	inventory.add_amount(ingredient, amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _on_sell_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return
	
	var final_amount : int = inventory.withdraw_item_by_id(ingredient_id, amount)
	
	if final_amount <= 0:
		return
		
	var sell_price : int = roundi(final_amount * ingredient.base_price * 0.75)
	money += sell_price #ei saa ihan samaa hintaa takas millä joskus osti...
	print(StringContainer.SELL_MESSAGE % [final_amount, sell_price])
	BrewerySignals.brewery_state_changed.emit(self)


func _on_start_brew() -> void:
	if brew_preparation.selected_contents.is_empty():
		print(StringContainer.TABLE_EMPTY_ERROR)
		return
	
	var brew_report : BrewResult = resolver.resolve_brew_style(brew_preparation.selected_contents)
	
	if brew_report == null:
		brew_preparation.clear_preparation()
		BrewerySignals.brewery_state_changed.emit(self)
		return 
	
	var new_batch := BrewBatch.new()
	new_batch.beer_style = brew_report.beer_style
	new_batch.amount_bottles = brew_report.bottle_yield
	new_batch.original_quality = brew_report.original_quality
	new_batch.final_ebc = brew_report.final_ebc
	new_batch.final_ibu = brew_report.final_ibu
	
	inventory.brew_batches.append(new_batch)
	
	brew_preparation.clear_preparation()
	print(StringContainer.SUCCESFULL_BREW_MESSAGE, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.brewery_state_changed.emit(self)
