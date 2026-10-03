class_name IngredientOptionButton
extends OptionButton


## The 13 hops overflow the 360 px viewport; PopupMenu scrolls once capped.
const POPUP_MAX_SIZE : Vector2i = Vector2i(10000, 200)
## Locked ingredients show their name, so the player can plan which one to unlock next.
const LOCKED_ITEM_FORMAT : String = "%s (maine %d)"
const LOCKED_TOOLTIP_FORMAT : String = "Vaatii mainetta: %d"

@export var target_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT

## Only a reputation change can lock or unlock items. brewery_state_changed fires on
## every buy and sale, and a rebuild resets the selection, so rebuild only then.
var _last_reputation_seen : int = -1


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

	_last_reputation_seen = _reputation()
	populate_ingredient_option_menu()


## Rebuilds on a reputation change but keeps the player's selection if it is still usable.
func _on_brewery_state_changed(brewery : Brewery) -> void:
	if brewery.reputation == _last_reputation_seen:
		return
	_last_reputation_seen = brewery.reputation

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


## Rebuilds and selects the first unlocked item: on _ready() and when the tab selector
## switches target_type.
func populate_ingredient_option_menu() -> void:
	_rebuild_items()

	var first_index := _first_enabled_index()
	if first_index != -1:
		select(first_index)
		# Deferred: during _ready() the parent views have not connected
		# active_ingredient_changed yet, and their slider would stay uninitialised.
		_on_item_selected.call_deferred(first_index)


func _rebuild_items() -> void:
	clear()
	var reputation : int = _reputation()
	var of_type : Array[IngredientData] = []
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]
		if ingredient.type == target_type:
			of_type.append(ingredient)
	for ingredient : IngredientData in IngredientMenuOrder.order(of_type, reputation):
		_add_ingredient_item(ingredient, IngredientMenuOrder.is_locked(ingredient, reputation))


func _add_ingredient_item(ingredient : IngredientData, is_locked : bool) -> void:
	add_item(tr(LOCKED_ITEM_FORMAT) % [tr(ingredient.name), ingredient.min_reputation] if is_locked else tr(ingredient.name))
	var new_item_index: int = get_item_count() - 1
	set_item_id(new_item_index, ingredient.id)
	set_item_disabled(new_item_index, is_locked)
	var tooltip : String = ingredient.get_tooltip_text()
	if is_locked:
		tooltip += "\n" + tr(LOCKED_TOOLTIP_FORMAT) % ingredient.min_reputation
	get_popup().set_item_tooltip(new_item_index, tooltip)


func _reputation() -> int:
	var brewery := BrewEngine.current_brewery
	return brewery.reputation if brewery != null else 0


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


## Some descriptions are wider than the 640 px viewport with Godot's default tooltip.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
