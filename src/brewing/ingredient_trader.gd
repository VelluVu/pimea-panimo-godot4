class_name IngredientTrader
extends RefCounted

## Buying and selling raw ingredients, plus the tutorial purchase tracking.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.buy_ingredient.connect(_on_buy_ingredient)
	GUISignals.sell_ingredient.connect(_on_sell_ingredient)


func disconnect_signals() -> void:
	GUISignals.buy_ingredient.disconnect(_on_buy_ingredient)
	GUISignals.sell_ingredient.disconnect(_on_sell_ingredient)


func _on_buy_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return

	if brewery.reputation < ingredient.min_reputation:
		print(StringContainer.INGREDIENT_LOCKED_ERROR % [ingredient.name, ingredient.min_reputation])
		BrewerySignals.ingredient_purchase_locked.emit(ingredient.name, ingredient.min_reputation)
		return

	var buy_price : int = roundi(ingredient.base_price * amount * brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE))

	if brewery.money < buy_price:
		print(StringContainer.RESOURCE_ERROR % [brewery.money, buy_price, StringContainer.MONEY_STRING])
		BrewerySignals.ingredient_purchase_underfunded.emit(ingredient.name, buy_price, brewery.money)
		return

	brewery.money -= buy_price
	brewery.inventory.add_amount(ingredient, amount)
	_track_tutorial_purchase(ingredient, amount)
	BrewerySignals.ingredient_purchased.emit(buy_price)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


func _track_tutorial_purchase(ingredient : IngredientData, amount : int) -> void:
	if ingredient.type == IngredientData.IngredientType.MALT:
		brewery.lifetime_malt_kg_bought += amount
		return

	var kotikalja : BeerStyle = brewery.resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)
	if kotikalja != null and ingredient.id == kotikalja.required_yeast_id:
		brewery.tutorial_bought_yeast = true


func _on_sell_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return
	
	var final_amount : int = brewery.inventory.withdraw_item_by_id(ingredient_id, amount)

	if final_amount <= 0:
		var held : InventoryItem = brewery.inventory.get_item_by_id(ingredient_id)
		BrewerySignals.ingredient_sale_failed.emit(ingredient.name, amount, held.amount if held != null else 0)
		return
		
	var sell_price : float = snappedf(final_amount * ingredient.base_price * brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE) * 0.75, 0.1)
	brewery.money += sell_price #ei saa ihan samaa hintaa takas millä joskus osti...
	print(StringContainer.SELL_MESSAGE % [final_amount, sell_price])
	BrewerySignals.brewery_state_changed.emit(brewery)
