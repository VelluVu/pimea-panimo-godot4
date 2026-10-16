class_name IngredientTrader
extends RefCounted

## Buying and selling raw ingredients, plus the tutorial purchase tracking.

const LOG_SOLD : String = "Sold %s amount of stuff, and you get %s€ back"
## Selling back never returns the full buy price.
const SELL_BACK_RATE : float = 0.75

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.buy_ingredient.connect(_on_buy_ingredient)
	GUISignals.sell_ingredient.connect(_on_sell_ingredient)
	GUISignals.buy_missing_for_recipe_requested.connect(_on_buy_missing_for_recipe_requested)


func disconnect_signals() -> void:
	GUISignals.buy_ingredient.disconnect(_on_buy_ingredient)
	GUISignals.sell_ingredient.disconnect(_on_sell_ingredient)
	GUISignals.buy_missing_for_recipe_requested.disconnect(_on_buy_missing_for_recipe_requested)


func _on_buy_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return

	if brewery.reputation < ingredient.min_reputation:
		print(StringContainer.INGREDIENT_LOCKED_ERROR % [ingredient.name, ingredient.min_reputation])
		BrewerySignals.ingredient_purchase_locked.emit(ingredient.name, ingredient.min_reputation)
		return

	var buy_price : float = snappedf(ingredient.base_price * amount * brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE), 0.01)

	if brewery.money < buy_price:
		print(StringContainer.RESOURCE_ERROR % [brewery.money, buy_price, StringContainer.MONEY_STRING])
		BrewerySignals.ingredient_purchase_underfunded.emit(ingredient.name, buy_price, brewery.money)
		return

	brewery.change_money(-buy_price, MoneyLedger.Source.INGREDIENTS)
	brewery.inventory.add_amount(ingredient, amount)
	_track_tutorial_purchase(ingredient, amount)
	BrewerySignals.ingredient_purchased.emit(buy_price)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


## Buys everything the loaded recipe still needs, all or nothing: a locked ingredient or
## too little money buys none of it, and says why like a single purchase does.
func _on_buy_missing_for_recipe_requested() -> void:
	var to_buy : Dictionary = RecipeShopping.missing(brewery.brew_preparation.active_recipe_target, brewery.owned_ingredient_amounts())
	if to_buy.is_empty():
		return
	var table : Dictionary = brewery.resolver.ingredient_table()
	var locked : IngredientData = RecipeShopping.first_locked(to_buy, table, brewery.reputation)
	if locked != null:
		BrewerySignals.ingredient_purchase_locked.emit(locked.name, locked.min_reputation)
		return
	var price : float = RecipeShopping.cost(to_buy, table, brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE))
	if brewery.money < price:
		BrewerySignals.ingredient_purchase_underfunded.emit(brewery.brew_preparation.active_recipe_style_name, price, brewery.money)
		return

	brewery.change_money(-price, MoneyLedger.Source.INGREDIENTS)
	for id : int in to_buy:
		var ingredient : IngredientData = table[id]
		brewery.inventory.add_amount(ingredient, to_buy[id])
		_track_tutorial_purchase(ingredient, to_buy[id])
	BrewerySignals.ingredient_purchased.emit(price)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


func _track_tutorial_purchase(ingredient : IngredientData, amount : int) -> void:
	if ingredient is MaltData:
		brewery.lifetime_malt_kg_bought += floori((ingredient as MaltData).kg(amount))
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
		
	var sell_price : float = snappedf(final_amount * ingredient.base_price * brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE) * SELL_BACK_RATE, 0.01)
	brewery.change_money(sell_price, MoneyLedger.Source.INGREDIENTS)
	print(LOG_SOLD % [final_amount, sell_price])
	BrewerySignals.brewery_state_changed.emit(brewery)
