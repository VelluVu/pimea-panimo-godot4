class_name IngredientMenuText
extends RefCounted

## An ingredient's line in the shop and brewery dropdowns: a target mark when the loaded
## recipe still needs it, and the stock, so the warehouse need not be opened to check.

const NEEDED_PREFIX : String = "🎯 "
const STOCK_FORMAT : String = "%s  (%s)"


## `stock_text` is the amount in the warehouse with its unit, empty when there is none.
static func item(ingredient_name : String, stock_text : String, needed : bool) -> String:
	var text : String = ingredient_name if stock_text.is_empty() else STOCK_FORMAT % [ingredient_name, stock_text]
	return NEEDED_PREFIX + text if needed else text
