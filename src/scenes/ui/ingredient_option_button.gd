class_name IngredientOptionButton
extends OptionButton


## The 13 hops overflow the 360 px viewport; PopupMenu scrolls once capped.
const POPUP_MAX_SIZE : Vector2i = Vector2i(10000, 200)
## Locked ingredients show their name, so the player can plan which one to unlock next.
const LOCKED_ITEM_FORMAT : String = "%s (maine %d)"
const LOCKED_TOOLTIP_FORMAT : String = "Vaatii mainetta: %d"
## An ingredient bought earlier stays usable when reputation falls below its bar.
const OWNED_LOCKED_TOOLTIP_FORMAT : String = "Lisää voi ostaa vasta %d maineella. Omistamasi määrän voi käyttää."

@export var target_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT
## In the shop an ingredient in stock already covers the recipe; the brewery needs it on
## the table. Decides which items get the "needed" mark.
var stock_covers_recipe : bool = false

## Rebuilds only when the locked set changed: brewery_state_changed fires on every buy and
## sale, and a rebuild resets the selection.
var _last_locked_ids : Array[int] = []


func _ready() -> void:
	clip_text = true
	fit_to_longest_item = false
	get_popup().max_size = POPUP_MAX_SIZE

	while not IngredientDatabase.is_loaded:
		await get_tree().process_frame

	item_selected.connect(_on_item_selected)
	pressed.connect(_on_menu_opened)
	GUISignals.active_ingredient_changed.connect(_on_global_ingredient_changed)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	_last_locked_ids = _locked_ids()
	populate_ingredient_option_menu()


## Rebuilds on a reputation change but keeps the player's selection if it is still usable.
func _on_brewery_state_changed(_brewery : Brewery) -> void:
	refresh_item_texts()
	var locked_ids : Array[int] = _locked_ids()
	if locked_ids == _last_locked_ids:
		return
	_last_locked_ids = locked_ids

	var previously_selected_id : int = get_item_id(selected) if selected != -1 else -1
	_rebuild_items()

	for i in range(item_count):
		if get_item_id(i) == previously_selected_id and not is_item_disabled(i):
			select(i)
			_sync_own_tooltip(previously_selected_id)
			return

	var first_index := _first_enabled_index()
	if first_index != -1:
		select(first_index)
		_on_item_selected(first_index)


## Locked items are disabled entries, so index 0 is not always pickable.
func _on_menu_opened() -> void:
	if selected != -1 and not is_item_disabled(selected):
		return

	var first_index := _first_enabled_index()
	if first_index == -1:
		return

	get_popup().set_focused_item(first_index)
	select(first_index)
	var first_id: int = get_item_id(first_index)
	if first_id != -1:
		GUISignals.active_ingredient_changed.emit(first_id)


## Rebuilds and selects the first unlocked item, on _ready() and on a tab switch.
func populate_ingredient_option_menu() -> void:
	_rebuild_items()

	var first_index := _first_enabled_index()
	if first_index != -1:
		select(first_index)
		# Deferred: in _ready() the views have not connected active_ingredient_changed yet.
		_on_item_selected.call_deferred(first_index)


func _rebuild_items() -> void:
	clear()
	var reputation : int = _reputation()
	var owned : Dictionary = _owned()
	for ingredient : IngredientData in IngredientMenuOrder.order(_of_type(), reputation, owned):
		_add_ingredient_item(ingredient, IngredientMenuOrder.is_locked(ingredient, reputation, owned), IngredientMenuOrder.is_buy_locked(ingredient, reputation))
	refresh_item_texts()


## Stock and the "needed" mark change on every buy and table move, without a rebuild
## (a rebuild would reset the selection). Locked items keep their reputation text.
func refresh_item_texts() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return
	var owned : Dictionary = brewery.owned_ingredient_amounts()
	var target : Dictionary = brewery.brew_preparation.active_recipe_target
	var table : Dictionary = brewery.brew_preparation.selected_contents
	for i : int in item_count:
		var ingredient : IngredientData = IngredientDatabase.get_item_by_id(get_item_id(i))
		if ingredient == null or is_item_disabled(i):
			continue
		var item : InventoryItem = brewery.inventory.get_item_by_id(ingredient.id)
		var in_stock : int = item.amount if item != null else 0
		var stock_text : String = "%s %s" % [ingredient.amount_text(in_stock), ingredient.get_unit_string()] if in_stock > 0 else ""
		var covered : int = owned.get(ingredient.id, 0) if stock_covers_recipe else table.get(ingredient.id, 0)
		set_item_text(i, IngredientMenuText.item(tr(ingredient.name), stock_text, target.get(ingredient.id, 0) > covered))


func _add_ingredient_item(ingredient : IngredientData, is_locked : bool, is_buy_locked : bool) -> void:
	add_item(tr(LOCKED_ITEM_FORMAT) % [tr(ingredient.name), ingredient.min_reputation] if is_locked else tr(ingredient.name))
	var new_item_index: int = get_item_count() - 1
	set_item_id(new_item_index, ingredient.id)
	set_item_disabled(new_item_index, is_locked)
	var tooltip : String = ingredient.get_tooltip_text()
	if is_locked:
		tooltip += "\n" + tr(LOCKED_TOOLTIP_FORMAT) % ingredient.min_reputation
	elif is_buy_locked:
		tooltip += "\n" + tr(OWNED_LOCKED_TOOLTIP_FORMAT) % ingredient.min_reputation
	get_popup().set_item_tooltip(new_item_index, tooltip)


## A seasonal ingredient out of its season is left out, unless some is still owned.
func _of_type() -> Array[IngredientData]:
	var of_type : Array[IngredientData] = []
	var season : SeasonRules.Season = SeasonRules.now()
	var owned : Dictionary = _owned()
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]
		if ingredient.type == target_type and (ingredient.is_sold_in(season) or owned.get(id, 0) > 0):
			of_type.append(ingredient)
	return of_type


func _locked_ids() -> Array[int]:
	var reputation : int = _reputation()
	var owned : Dictionary = _owned()
	var ids : Array[int] = []
	for ingredient : IngredientData in _of_type():
		if IngredientMenuOrder.is_locked(ingredient, reputation, owned):
			ids.append(ingredient.id)
	return ids


func _reputation() -> int:
	var brewery := BrewEngine.current_brewery
	return brewery.reputation if brewery != null else 0


func _owned() -> Dictionary:
	var brewery := BrewEngine.current_brewery
	return brewery.owned_ingredient_amounts() if brewery != null else {}


func _first_enabled_index() -> int:
	for i in range(item_count):
		if not is_item_disabled(i):
			return i
	return -1


func _on_item_selected(index: int) -> void:
	var selected_id: int = get_item_id(index)
	if selected_id != -1:
		_sync_own_tooltip(selected_id)
		GUISignals.active_ingredient_changed.emit(selected_id)


func _on_global_ingredient_changed(ingredient_id: int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)

	if ingredient and ingredient.type == target_type:
		for i in range(item_count):
			if get_item_id(i) == ingredient_id:
				select(i)
				_sync_own_tooltip(ingredient_id)
				return
	else:
		var first_index := _first_enabled_index()
		if first_index != -1:
			select(first_index)


## The closed button shows the same info as the popup item, without a click.
func _sync_own_tooltip(ingredient_id : int) -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient:
		tooltip_text = ingredient.get_tooltip_text()


## Some descriptions are wider than the viewport with Godot's default tooltip.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
