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

## Set by the BrewerySignals failure handlers below while an osta/myy command
## is in flight; the command clears it before emitting and reads it after,
## since GUISignals.buy_ingredient/sell_ingredient are fire-and-forget.
var _trade_failure_reason : String = ""


func register(register_command : Callable) -> void:
	BrewerySignals.ingredient_purchase_locked.connect(_on_purchase_locked)
	BrewerySignals.ingredient_purchase_underfunded.connect(_on_purchase_underfunded)
	BrewerySignals.ingredient_sale_failed.connect(_on_sale_failed)
	register_command.call("osta", _cmd_osta, "osta <ainesosa> <määrä>")
	register_command.call("myy", _cmd_myy, "myy <ainesosa> <määrä>")
	register_command.call("pöytään", _cmd_poytaan, "pöytään <ainesosa> <määrä>")
	register_command.call("poista", _cmd_poista_poydalta, "poista <ainesosa> <määrä>")
	register_command.call("tyhjennä", _cmd_tyhjenna)
	register_command.call("tallenna", _cmd_tallenna)
	register_command.call("pane", _cmd_pane)
	register_command.call("keitä", _cmd_keita, "keitä <resepti>")


func _on_purchase_locked(ingredient_name: String, required_reputation: int) -> void:
	_trade_failure_reason = PURCHASE_LOCKED_REASON % [ingredient_name, required_reputation]


func _on_purchase_underfunded(ingredient_name: String, price: int, money: float) -> void:
	_trade_failure_reason = PURCHASE_UNDERFUNDED_REASON % [ingredient_name, price, money]


func _on_sale_failed(ingredient_name: String, requested: int, in_stock: int) -> void:
	_trade_failure_reason = SALE_FAILED_REASON % [ingredient_name, requested, in_stock]


func _cmd_osta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.buy_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log("Ostettu: %s x%d" % [parsed.ingredient.name, parsed.amount])
	else:
		_log(TRADE_FAILED_MESSAGE % ["Ostaminen", _trade_failure_reason])


func _cmd_myy(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.sell_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log("Myyty: %s x%d" % [parsed.ingredient.name, parsed.amount])
	else:
		_log(TRADE_FAILED_MESSAGE % ["Myyminen", _trade_failure_reason])


func _cmd_poytaan(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.add_ingredient_to_brew_preparation.emit(parsed.id, parsed.amount)
	_log("Pöydälle lisätty: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_poista_poydalta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.remove_ingredients_from_brew_preparation.emit(parsed.id, parsed.amount)
	_log("Poistettu pöydältä: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_tyhjenna(_args: PackedStringArray) -> void:
	GUISignals.clear_brew_preparation_requested.emit()
	_log("Valmistelu tyhjennetty, ainekset palautettu varastoon.")


func _cmd_tallenna(_args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	var recipes_before : int = brewery.saved_recipes.size()
	GUISignals.save_recipe_requested.emit()

	# Success is already logged by _on_recipe_saved() via BrewerySignals.recipe_saved.
	if brewery.saved_recipes.size() == recipes_before:
		_log(RECIPE_NOT_SAVED_MESSAGE)


func _cmd_pane(_args: PackedStringArray) -> void:
	GUISignals.start_brewing.emit()


func _cmd_keita(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.is_empty():
		_log("Käyttö: keitä <resepti>. Tallennetut: %s" % _saved_recipe_names(brewery))
		return

	var wanted := " ".join(Array(args)).to_lower()
	var matched : BrewRecipe = null
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.recipe_name.to_lower().contains(wanted):
			matched = recipe
			break

	if matched == null:
		_log("Reseptiä ei löytynyt: %s. Tallennetut: %s" % [" ".join(Array(args)), _saved_recipe_names(brewery)])
		return

	var batches_before : int = brewery.inventory.brew_batches.size()
	GUISignals.load_recipe_requested.emit(matched)
	GUISignals.start_brewing.emit()

	if brewery.inventory.brew_batches.size() > batches_before:
		_log("Keitetään: %s" % matched.recipe_name)
	else:
		_log("Keittäminen epäonnistui: %s (ei tarpeeksi ainesosia varastossa?)" % matched.recipe_name)


func _saved_recipe_names(brewery : Brewery) -> String:
	var names : Array[String] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		names.append(recipe.recipe_name)
	return ", ".join(names) if not names.is_empty() else "(ei tallennettuja reseptejä)"


## Takes the trailing token as the amount and everything before it (joined)
## as an ingredient name search — matched by prefix first, then substring,
## against IngredientDatabase, so "osta pilsner 5" or "osta citra humala 20"
## both work without needing the ingredient's exact full name.
func _parse_ingredient_amount(args: PackedStringArray) -> Dictionary:
	if args.size() < 2 or not args[args.size() - 1].is_valid_int():
		_log("Käyttö: <komento> <ainesosa> <määrä>")
		return {}

	var amount : int = args[args.size() - 1].to_int()
	if amount <= 0:
		_log("Määrän täytyy olla suurempi kuin 0.")
		return {}

	var query := " ".join(Array(args.slice(0, args.size() - 1))).to_lower()
	var ingredient : IngredientData = _find_ingredient_by_name(query)
	if ingredient == null:
		_log("Ainesosaa ei löytynyt: %s" % query)
		return {}

	return {"id": ingredient.id, "amount": amount, "ingredient": ingredient}


func _find_ingredient_by_name(query : String) -> IngredientData:
	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data.name.to_lower().begins_with(query):
			return data

	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data.name.to_lower().contains(query):
			return data

	return null
