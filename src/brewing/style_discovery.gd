class_name StyleDiscovery
extends RefCounted

## Style discovery: marking a style known, guaranteeing it has a default recipe,
## and pre-seeding styles found in earlier runs.


var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


## Pre-seeds styles found in earlier runs so a new run starts knowing what the
## player already knows. A loading save overwrites this with its own values.
## MetaProgressManager is null while BrewEngine builds its boot-time Brewery.
func seed_from_meta() -> void:
	if MetaProgressManager == null:
		return
	for style : int in MetaProgressManager.get_discovered_styles():
		if brewery.discovered_styles.has(style):
			continue
		brewery.discovered_styles[style] = true
		ensure_default_recipe(brewery.resolver.get_beer_style(style), false)


func discover_style(style : BeerStyle.Style) -> void:
	if brewery.discovered_styles.has(style):
		return

	brewery.discovered_styles[style] = true
	ensure_default_recipe(brewery.resolver.get_beer_style(style))
	BrewerySignals.style_discovered.emit(style)


## Guarantees a style has a saved default recipe of its minimum ingredients,
## returning the existing one if present. `emit_state_changed` is false from
## Brewery._init(): it also runs while a save loads, and must not broadcast
## half-built state.
func ensure_default_recipe(beer_style : BeerStyle, emit_state_changed : bool = true) -> BrewRecipe:
	if beer_style == null:
		return null

	for existing : BrewRecipe in brewery.saved_recipes:
		if existing.beer_style == beer_style.style and existing.is_default:
			return existing

	var ingredients : Dictionary = brewery.resolver.compute_minimum_ingredients(beer_style)
	if ingredients.is_empty():
		return null

	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredients
	recipe.recipe_name = "%s (perusresepti)" % beer_style.style_name
	recipe.is_default = true

	brewery.saved_recipes.append(recipe)
	if emit_state_changed:
		BrewerySignals.brewery_state_changed.emit(brewery)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)

	return recipe
