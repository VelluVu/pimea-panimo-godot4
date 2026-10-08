class_name RecipeSaveRules
extends RefCounted

## Whether the brewing table may be saved as a recipe, and why not.

enum Rejection { NONE, NO_STYLE, UNKNOWN_STYLE, DUPLICATE }


static func rejection(preview : BrewResult, style_known : bool, contents : Dictionary, saved_recipes : Array[BrewRecipe]) -> Rejection:
	# An unmatched brew still carries a placeholder style, so check the match first.
	if preview == null or not preview.is_matched:
		return Rejection.NO_STYLE
	# Saving would reveal an undiscovered style's name. Styles save themselves when discovered.
	if not style_known:
		return Rejection.UNKNOWN_STYLE
	if find_same(contents, saved_recipes) != null:
		return Rejection.DUPLICATE
	return Rejection.NONE


static func find_same(contents : Dictionary, saved_recipes : Array[BrewRecipe]) -> BrewRecipe:
	for recipe : BrewRecipe in saved_recipes:
		if same_amounts(contents, recipe.ingredient_amounts):
			return recipe
	return null


## Compared as ints: amounts loaded from a save can come back as floats.
static func same_amounts(a : Dictionary, b : Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for id : Variant in a:
		if not b.has(int(id)) or int(b[int(id)]) != int(a[id]):
			return false
	return true
