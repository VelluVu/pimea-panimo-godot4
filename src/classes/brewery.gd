class_name Brewery
extends Resource


const AVI_RAID_THRESHOLD : int = 100
const AVI_RAID_FINE_PERCENT : float = 0.3
const AVI_RAID_REPUTATION_PENALTY_PERCENT : float = 0.25

@export var inventory : Inventory
@export var current_day : int = 1
@export var money: int = 100
@export var risk: int = 0
@export var reputation: int = 0
@export var brew_preparation : BrewPreparation
@export var saved_recipes : Array[BrewRecipe] = []
var resolver : BrewResolver = null
@export var discovered_styles : Dictionary = {} # Avain: BeerStyle.Style -> Arvo: true


func _init() -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()
	resolver = BrewResolver.new()
	resolver._ready()
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Zero-click first-brew hint: Kotikalja is known from the start without
	# ever being brewed, so it never goes through discover_style()'s
	# default-recipe seeding below — seed it here instead.
	var kotikalja_recipe : BrewRecipe = _ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	if kotikalja_recipe != null:
		brew_preparation.active_recipe_target = kotikalja_recipe.ingredient_amounts.duplicate()
		brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(kotikalja_recipe.beer_style)


func is_style_known(style : BeerStyle.Style) -> bool:
	return BrewEngine.DEVELOPER_MODE or discovered_styles.has(style)


func discover_style(style : BeerStyle.Style) -> void:
	if discovered_styles.has(style):
		return

	discovered_styles[style] = true
	_ensure_default_recipe(resolver.get_beer_style(style))
	BrewerySignals.style_discovered.emit(style)


## Guarantees every unlocked style has at least one saved recipe showing
## its bare-minimum valid ingredients, even for styles unlocked without
## ever being brewed (Kotikalja) or where the player's own brew used more
## than the minimum. Idempotent — returns the existing default recipe
## if this style already has one instead of adding a duplicate.
func _ensure_default_recipe(beer_style : BeerStyle) -> BrewRecipe:
	if beer_style == null:
		return null

	for existing : BrewRecipe in saved_recipes:
		if existing.beer_style == beer_style.style and existing.is_default:
			return existing

	var ingredients : Dictionary = resolver.compute_minimum_ingredients(beer_style)
	if ingredients.is_empty():
		return null

	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredients
	recipe.recipe_name = "%s (perusresepti)" % beer_style.style_name
	recipe.is_default = true

	saved_recipes.append(recipe)
	BrewerySignals.brewery_state_changed.emit(self)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)

	return recipe


func add_risk(amount : int) -> void:
	risk = max(0, risk + amount)
	_check_for_avi_raid()


func clear_risk() -> void:
	risk = 0


func _check_for_avi_raid() -> void:
	if risk < AVI_RAID_THRESHOLD:
		return

	var confiscated_bottles : int = _count_total_bottles()
	inventory.brew_batches.clear()

	var fine_amount : int = roundi(money * AVI_RAID_FINE_PERCENT)
	var reputation_penalty : int = roundi(reputation * AVI_RAID_REPUTATION_PENALTY_PERCENT)

	money -= fine_amount
	reputation = max(0, reputation - reputation_penalty)
	risk = 0

	BrewerySignals.avi_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
	BrewerySignals.brewery_state_changed.emit(self)


func _count_total_bottles() -> int:
	var total : int = 0

	for batch : BrewBatch in inventory.brew_batches:
		total += batch.amount_bottles

	return total


func _ready() -> void:
	GUISignals.add_ingredient_to_brew_preparation.connect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.connect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.connect(_on_buy_ingredient)
	GUISignals.sell_ingredient.connect(_on_sell_ingredient)
	GUISignals.start_brewing.connect(start_brew)
	GUISignals.save_recipe_requested.connect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.connect(_on_load_recipe_requested)
	GUISignals.clear_brew_preparation_requested.connect(_on_clear_brew_preparation_requested)


## Must be called on the outgoing Brewery before BrewEngine.current_brewery
## is replaced (new game, load game) — otherwise the old instance stays
## connected to GUISignals forever (Godot keeps it alive via the signal
## connection) and silently keeps handling player actions instead of the
## one actually shown on screen.
func disconnect_signals() -> void:
	GUISignals.add_ingredient_to_brew_preparation.disconnect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.disconnect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.disconnect(_on_buy_ingredient)
	GUISignals.sell_ingredient.disconnect(_on_sell_ingredient)
	GUISignals.start_brewing.disconnect(start_brew)
	GUISignals.save_recipe_requested.disconnect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.disconnect(_on_load_recipe_requested)
	GUISignals.clear_brew_preparation_requested.disconnect(_on_clear_brew_preparation_requested)


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


func _on_save_recipe_requested() -> void:
	if brew_preparation.selected_contents.is_empty():
		return

	var preview : BrewResult = resolver.resolve_brew_style(brew_preparation.selected_contents)
	if preview == null:
		return

	# Don't let the player name-peek an undiscovered style just by saving the
	# recipe — that would spoil the "brew it to find out" surprise. Styles
	# save themselves automatically the moment they're actually discovered.
	if not is_style_known(preview.beer_style.style):
		BrewerySignals.recipe_save_rejected.emit()
		return

	_save_recipe(preview.beer_style, brew_preparation.selected_contents.duplicate())


func _save_recipe(beer_style : BeerStyle, ingredient_amounts : Dictionary) -> void:
	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredient_amounts

	var existing_count : int = 0
	for other_recipe : BrewRecipe in saved_recipes:
		if other_recipe.beer_style == recipe.beer_style:
			existing_count += 1

	recipe.recipe_name = "%s #%d" % [beer_style.style_name, existing_count + 1]

	saved_recipes.append(recipe)
	BrewerySignals.brewery_state_changed.emit(self)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)


## Clears whatever's currently on the brewing table, refunding it to
## inventory first — used by the brew preparation panel's erase button.
func _on_clear_brew_preparation_requested() -> void:
	for ingredient_id : int in brew_preparation.selected_contents:
		var amount : int = brew_preparation.selected_contents[ingredient_id]
		inventory.add_amount_by_id(ingredient_id, amount)

	brew_preparation.clear_preparation()
	BrewerySignals.brewery_state_changed.emit(self)


func _on_load_recipe_requested(recipe : BrewRecipe) -> void:
	if recipe == null:
		return

	brew_preparation.active_recipe_target = recipe.ingredient_amounts.duplicate()
	brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(recipe.beer_style)

	for ingredient_id : int in recipe.ingredient_amounts:
		var wanted : int = recipe.ingredient_amounts[ingredient_id]
		var item : InventoryItem = inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		var withdrawn : int = inventory.withdraw_item_by_id(ingredient_id, min(wanted, available))

		if withdrawn > 0:
			brew_preparation.add_to_table(ingredient_id, withdrawn)

	BrewerySignals.brewery_state_changed.emit(self)


func start_brew() -> void:
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
	new_batch.current_quality = brew_report.original_quality
	new_batch.final_ebc = brew_report.final_ebc
	new_batch.final_ibu = brew_report.final_ibu
	new_batch.precision_score = brew_report.precision_score
	new_batch.hop_diversity_count = brew_report.hop_diversity_count
	new_batch.hop_balance_bonus = brew_report.hop_balance_bonus
	new_batch.flavor_matched = brew_report.flavor_matched

	inventory.brew_batches.append(new_batch)

	if brew_report.is_matched:
		var is_new_discovery : bool = not discovered_styles.has(brew_report.beer_style.style)
		discover_style(brew_report.beer_style.style)
		if is_new_discovery:
			_save_recipe(brew_report.beer_style, brew_preparation.selected_contents.duplicate())

	brew_preparation.clear_preparation()
	print(StringContainer.SUCCESFULL_BREW_MESSAGE, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.brewery_state_changed.emit(self)