class_name RecipeNameText
extends RefCounted

## Saved recipe names. A recipe stores its Finnish name (older saves rely on it), so the
## shown name is rebuilt from the recipe's style and number in the active language.

const DEFAULT_FORMAT : String = "%s (perusresepti)"
const NUMBERED_FORMAT : String = "%s #%d"

static var _number_suffix := RegEx.create_from_string("#(\\d+)$")


static func default_name(style_name : String) -> String:
	return DEFAULT_FORMAT % style_name


static func numbered_name(style_name : String, number : int) -> String:
	return NUMBERED_FORMAT % [style_name, number]


## The stored name comes back as it is when it has no number to rebuild from.
static func display(recipe : BrewRecipe) -> String:
	var style_name : String = BeerStyle.get_style_string_from_style(recipe.beer_style)
	if recipe.is_default:
		return UiText.of(DEFAULT_FORMAT) % style_name
	var found : RegExMatch = _number_suffix.search(recipe.recipe_name)
	if found == null:
		return recipe.recipe_name
	return NUMBERED_FORMAT % [style_name, found.get_string(1).to_int()]
