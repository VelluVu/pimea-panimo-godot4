class_name RecipeBook
extends RefCounted

## Owns the saved-recipe and brewing-table player actions (save, load, fill,
## clear) that used to live on Brewery. Signal handlers only: the state itself
## (saved_recipes, brew_preparation, inventory) stays on the Brewery resource so
## saves keep working.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.save_recipe_requested.connect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.connect(_on_load_recipe_requested)
	GUISignals.fill_recipe_from_inventory_requested.connect(_on_fill_recipe_from_inventory_requested)
	GUISignals.clear_brew_preparation_requested.connect(_on_clear_brew_preparation_requested)


## Must run before the owning Brewery is replaced, see Brewery.disconnect_signals().
func disconnect_signals() -> void:
	GUISignals.save_recipe_requested.disconnect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.disconnect(_on_load_recipe_requested)
	GUISignals.fill_recipe_from_inventory_requested.disconnect(_on_fill_recipe_from_inventory_requested)
	GUISignals.clear_brew_preparation_requested.disconnect(_on_clear_brew_preparation_requested)


func _on_save_recipe_requested() -> void:
	if brewery.brew_preparation.selected_contents.is_empty():
		return

	var preview : BrewResult = brewery.resolver.resolve_brew_style(brewery.brew_preparation.selected_contents)
	if preview == null:
		return

	# Don't let the player name-peek an undiscovered style just by saving the
	# recipe — that would spoil the "brew it to find out" surprise. Styles
	# save themselves automatically the moment they're actually discovered.
	if not brewery.is_style_known(preview.beer_style.style):
		BrewerySignals.recipe_save_rejected.emit()
		return

	save_recipe(preview.beer_style, brewery.brew_preparation.selected_contents.duplicate())


func save_recipe(beer_style : BeerStyle, ingredient_amounts : Dictionary) -> void:
	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredient_amounts

	var existing_count : int = 0
	for other_recipe : BrewRecipe in brewery.saved_recipes:
		if other_recipe.beer_style == recipe.beer_style:
			existing_count += 1

	recipe.recipe_name = "%s #%d" % [beer_style.style_name, existing_count + 1]

	brewery.saved_recipes.append(recipe)
	BrewerySignals.brewery_state_changed.emit(brewery)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)


## Clears whatever's currently on the brewing table, refunding it to
## inventory first — used by the brew preparation panel's erase button.
func _on_clear_brew_preparation_requested() -> void:
	for ingredient_id : int in brewery.brew_preparation.selected_contents:
		var amount : int = brewery.brew_preparation.selected_contents[ingredient_id]
		brewery.inventory.add_amount_by_id(ingredient_id, amount)

	brewery.brew_preparation.clear_preparation()
	BrewerySignals.brewery_state_changed.emit(brewery)


func _on_load_recipe_requested(recipe : BrewRecipe) -> void:
	if recipe == null:
		return

	brewery.brew_preparation.active_recipe_target = recipe.ingredient_amounts.duplicate()
	brewery.brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(recipe.beer_style)

	for ingredient_id : int in recipe.ingredient_amounts:
		var wanted : int = recipe.ingredient_amounts[ingredient_id]
		var item : InventoryItem = brewery.inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		var withdrawn : int = brewery.inventory.withdraw_item_by_id(ingredient_id, min(wanted, available))

		if withdrawn > 0:
			brewery.brew_preparation.add_to_table(ingredient_id, withdrawn)

	BrewerySignals.brewery_state_changed.emit(brewery)


## Tops the table up to the currently active recipe's target amounts —
## unlike _on_load_recipe_requested() above (which withdraws whatever it
## can even if that's short of the target, since loading IS the point at
## which a fresh target gets set), this is strictly all-or-nothing: it
## checks every missing ingredient against inventory FIRST, and refuses
## outright if any single one is short, rather than partially draining
## inventory into a table that still can't brew. BrewPreparationPanel
## mirrors this same check to keep its "Täytä" button disabled whenever
## this would refuse, so a real player should never actually reach the
## refusal path — same defense-in-depth reasoning as the reputation guard
## in _on_ship_batch_to_bar_requested().
func _on_fill_recipe_from_inventory_requested() -> void:
	var recipe_target : Dictionary = brewery.brew_preparation.active_recipe_target
	if recipe_target.is_empty():
		return

	var missing_amounts : Dictionary = {}
	for ingredient_id : int in recipe_target:
		var required : int = recipe_target[ingredient_id]
		var on_table : int = brewery.brew_preparation.selected_contents.get(ingredient_id, 0)
		var missing : int = required - on_table
		if missing <= 0:
			continue

		var item : InventoryItem = brewery.inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		if available < missing:
			return

		missing_amounts[ingredient_id] = missing

	if missing_amounts.is_empty():
		return

	for ingredient_id : int in missing_amounts:
		var withdrawn : int = brewery.inventory.withdraw_item_by_id(ingredient_id, missing_amounts[ingredient_id])
		brewery.brew_preparation.add_to_table(ingredient_id, withdrawn)

	BrewerySignals.brewery_state_changed.emit(brewery)
