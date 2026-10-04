class_name PlayerCommands
extends ConsoleCommandSet

## Player-tier console commands: text shortcuts for actions the UI already
## allows (shop, brewing table, recipes). They wrap the exact GUISignals a
## button click fires, so no economy or unlock rule is bypassed.

const TRADE_FAILED_MESSAGE: String = "[color=orange]%s epäonnistui: %s[/color]"

const PURCHASE_LOCKED_REASON: String = "%s vaatii mainetta %d"

const PURCHASE_UNDERFUNDED_REASON: String = "%s maksaa %d €, rahaa %.1f €"

const SALE_FAILED_REASON: String = "%s: pyydetty %d, varastossa %d"

const RECIPE_NOT_SAVED_MESSAGE: String = "Reseptiä ei tallennettu (pöytä tyhjä tai oluttyyli ei vielä tuttu)"

const BOUGHT_MESSAGE: String = "Ostettu: %s x%d"
const BUYING_TEXT: String = "Ostaminen"
const SOLD_MESSAGE: String = "Myyty: %s x%d"
const SELLING_TEXT: String = "Myyminen"
const ADDED_TO_TABLE_MESSAGE: String = "Pöydälle lisätty: %s x%d"
const REMOVED_FROM_TABLE_MESSAGE: String = "Poistettu pöydältä: %s x%d"
const TABLE_CLEARED_MESSAGE: String = "Valmistelu tyhjennetty, ainekset palautettu varastoon."
const NO_BREWERY_MESSAGE: String = "Ei aktiivista panimoa."
const KEITA_USAGE_MESSAGE: String = "Käyttö: keitä <resepti>. Tallennetut: %s"
const RECIPE_NOT_FOUND_MESSAGE: String = "Reseptiä ei löytynyt: %s. Tallennetut: %s"
const BREWING_MESSAGE: String = "Keitetään: %s"
const BREWING_FAILED_MESSAGE: String = "Keittäminen epäonnistui: %s (ei tarpeeksi ainesosia varastossa?)"
const NO_SAVED_RECIPES_TEXT: String = "(ei tallennettuja reseptejä)"
const AMOUNT_USAGE_MESSAGE: String = "Käyttö: <komento> <ainesosa> <määrä>"
const AMOUNT_NOT_POSITIVE_MESSAGE: String = "Määrän täytyy olla suurempi kuin 0."
const INGREDIENT_NOT_FOUND_MESSAGE: String = "Ainesosaa ei löytynyt: %s"

const OSTA_USAGE_TEXT: String = "osta <ainesosa> <määrä>"
const MYY_USAGE_TEXT: String = "myy <ainesosa> <määrä>"
const POYTAAN_USAGE_TEXT: String = "pöytään <ainesosa> <määrä>"
const POISTA_USAGE_TEXT: String = "poista <ainesosa> <määrä>"
const KEITA_USAGE_TEXT: String = "keitä <resepti>"

## Set by the BrewerySignals failure handlers below while an osta/myy command
## is in flight; the command clears it before emitting and reads it after,
## since GUISignals.buy_ingredient/sell_ingredient are fire-and-forget.
var _trade_failure_reason : String = ""


func register(register_command : Callable) -> void:
	BrewerySignals.ingredient_purchase_locked.connect(_on_purchase_locked)
	BrewerySignals.ingredient_purchase_underfunded.connect(_on_purchase_underfunded)
	BrewerySignals.ingredient_sale_failed.connect(_on_sale_failed)
	register_command.call("osta", _cmd_osta, OSTA_USAGE_TEXT)
	register_command.call("myy", _cmd_myy, MYY_USAGE_TEXT)
	register_command.call("pöytään", _cmd_poytaan, POYTAAN_USAGE_TEXT)
	register_command.call("poista", _cmd_poista_poydalta, POISTA_USAGE_TEXT)
	register_command.call("tyhjennä", _cmd_tyhjenna)
	register_command.call("tallenna", _cmd_tallenna)
	register_command.call("pane", _cmd_pane)
	register_command.call("keitä", _cmd_keita, KEITA_USAGE_TEXT)


func _on_purchase_locked(ingredient_name: String, required_reputation: int) -> void:
	_trade_failure_reason = tr(PURCHASE_LOCKED_REASON) % [tr(ingredient_name), required_reputation]


func _on_purchase_underfunded(ingredient_name: String, price: int, money: float) -> void:
	_trade_failure_reason = tr(PURCHASE_UNDERFUNDED_REASON) % [tr(ingredient_name), price, money]


func _on_sale_failed(ingredient_name: String, requested: int, in_stock: int) -> void:
	_trade_failure_reason = tr(SALE_FAILED_REASON) % [tr(ingredient_name), requested, in_stock]


func _cmd_osta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.buy_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log(tr(BOUGHT_MESSAGE) % [tr(parsed.ingredient.name), parsed.amount])
	else:
		_log(tr(TRADE_FAILED_MESSAGE) % [tr(BUYING_TEXT), _trade_failure_reason])


func _cmd_myy(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.sell_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log(tr(SOLD_MESSAGE) % [tr(parsed.ingredient.name), parsed.amount])
	else:
		_log(tr(TRADE_FAILED_MESSAGE) % [tr(SELLING_TEXT), _trade_failure_reason])


func _cmd_poytaan(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.add_ingredient_to_brew_preparation.emit(parsed.id, parsed.amount)
	_log(tr(ADDED_TO_TABLE_MESSAGE) % [tr(parsed.ingredient.name), parsed.amount])


func _cmd_poista_poydalta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.remove_ingredients_from_brew_preparation.emit(parsed.id, parsed.amount)
	_log(tr(REMOVED_FROM_TABLE_MESSAGE) % [tr(parsed.ingredient.name), parsed.amount])


func _cmd_tyhjenna(_args: PackedStringArray) -> void:
	GUISignals.clear_brew_preparation_requested.emit()
	_log(tr(TABLE_CLEARED_MESSAGE))


func _cmd_tallenna(_args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log(tr(NO_BREWERY_MESSAGE))
		return

	var recipes_before : int = brewery.saved_recipes.size()
	GUISignals.save_recipe_requested.emit()

	# Success is already logged by _on_recipe_saved() via BrewerySignals.recipe_saved.
	if brewery.saved_recipes.size() == recipes_before:
		_log(tr(RECIPE_NOT_SAVED_MESSAGE))


func _cmd_pane(_args: PackedStringArray) -> void:
	GUISignals.start_brewing.emit()


func _cmd_keita(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log(tr(NO_BREWERY_MESSAGE))
		return

	if args.is_empty():
		_log(tr(KEITA_USAGE_MESSAGE) % _saved_recipe_names(brewery))
		return

	var wanted := " ".join(Array(args)).to_lower()
	var matched : BrewRecipe = null
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.recipe_name.to_lower().contains(wanted) or RecipeNameText.display(recipe).to_lower().contains(wanted):
			matched = recipe
			break

	if matched == null:
		_log(tr(RECIPE_NOT_FOUND_MESSAGE) % [" ".join(Array(args)), _saved_recipe_names(brewery)])
		return

	var batches_before : int = brewery.inventory.brew_batches.size()
	GUISignals.load_recipe_requested.emit(matched)
	GUISignals.start_brewing.emit()

	if brewery.inventory.brew_batches.size() > batches_before:
		_log(tr(BREWING_MESSAGE) % RecipeNameText.display(matched))
	else:
		_log(tr(BREWING_FAILED_MESSAGE) % RecipeNameText.display(matched))


func _saved_recipe_names(brewery : Brewery) -> String:
	var names : Array[String] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		names.append(RecipeNameText.display(recipe))
	return ", ".join(names) if not names.is_empty() else tr(NO_SAVED_RECIPES_TEXT)


## Takes the trailing token as the amount and everything before it (joined)
## as an ingredient name search — matched by prefix first, then substring,
## against IngredientDatabase, so "osta pilsner 5" or "osta citra humala 20"
## both work without needing the ingredient's exact full name.
func _parse_ingredient_amount(args: PackedStringArray) -> Dictionary:
	if args.size() < 2 or not args[args.size() - 1].is_valid_int():
		_log(tr(AMOUNT_USAGE_MESSAGE))
		return {}

	var amount : int = args[args.size() - 1].to_int()
	if amount <= 0:
		_log(tr(AMOUNT_NOT_POSITIVE_MESSAGE))
		return {}

	var query := " ".join(Array(args.slice(0, args.size() - 1))).to_lower()
	var ingredient : IngredientData = _find_ingredient_by_name(query)
	if ingredient == null:
		_log(tr(INGREDIENT_NOT_FOUND_MESSAGE) % query)
		return {}

	return {"id": ingredient.id, "amount": amount, "ingredient": ingredient}


func _find_ingredient_by_name(query : String) -> IngredientData:
	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if _names_of(data).any(func(name: String) -> bool: return name.begins_with(query)):
			return data

	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if _names_of(data).any(func(name: String) -> bool: return name.contains(query)):
			return data

	return null


## The Finnish name and the one shown in the current language, so either can be typed.
func _names_of(data : IngredientData) -> Array[String]:
	return [data.name.to_lower(), tr(data.name).to_lower()]
