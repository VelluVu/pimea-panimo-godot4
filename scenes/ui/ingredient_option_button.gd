class_name IngredientOptionButton
extends OptionButton


@export var target_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT

## Tracks reputation between brewery_state_changed emissions so this only
## rebuilds the list on an actual reputation change (crossing a hop's
## min_reputation) instead of on every state change (a buy, sell, or sale
## fires this signal far too often to rebuild — and clearing/rebuilding
## resets the current selection, which would be disruptive mid-shop).
var _last_reputation_seen : int = -1


func _ready() -> void:
	clip_text = true
	fit_to_longest_item = false

	while not IngredientDatabase.is_loaded:
		await get_tree().process_frame

	item_selected.connect(_on_item_selected)
	pressed.connect(_on_menu_opened)
	GUISignals.active_ingredient_changed.connect(_on_global_ingredient_changed)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	var brewery := BrewEngine.current_brewery
	_last_reputation_seen = brewery.reputation if brewery != null else 0
	populate_ingredient_option_menu()


## Reputation crossing a hop's min_reputation is the only thing that can
## change which items are locked, so this only rebuilds on an actual
## reputation change — not on every state change (a buy/sell/sale fires
## brewery_state_changed far too often for that) — and restores the
## player's current selection afterward instead of resetting to the first
## item like a fresh populate_ingredient_option_menu() call would.
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


func _on_menu_opened() -> void:
	# Only force-reselect the first item if nothing valid is currently
	# selected — a locked ingredient sits in the list as a disabled entry
	# (see populate_ingredient_option_menu()), so this can no longer assume
	# index 0 is always pickable.
	if selected != -1 and not is_item_disabled(selected):
		return

	var first_index := _first_enabled_index()
	if first_index == -1:
		return

	var popup: PopupMenu = get_popup()
	popup.set_focused_item(first_index)
	select(first_index)
	var first_id = get_item_id(first_index)

	if first_id != -1:
		GUISignals.active_ingredient_changed.emit(first_id)


## Rebuilds the list and defaults the selection to the first unlocked item —
## called on _ready() and whenever the tab selector switches target_type
## (ingredient_type_selector.gd), both cases where a fresh default selection
## is correct. See _on_brewery_state_changed() for the one case (a
## reputation change mid-shop) where the current selection must be
## preserved instead.
func populate_ingredient_option_menu() -> void:
	_rebuild_items()

	var first_index := _first_enabled_index()
	if first_index != -1:
		select(first_index)
		# Deferred: this can run during _ready(), before ancestor views
		# (BrewingView/ShopView) have connected active_ingredient_changed —
		# emitting synchronously here would fire into the void and leave
		# their slider/label stuck uninitialized until the player manually
		# reselects. Deferring pushes it past the whole tree's _ready() pass.
		_on_item_selected.call_deferred(first_index)


func _rebuild_items() -> void:
	clear()
	var brewery := BrewEngine.current_brewery
	var reputation : int = brewery.reputation if brewery != null else 0

	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]

		if ingredient.type == target_type:
			var is_locked : bool = reputation < ingredient.min_reputation
			add_item(StringContainer.INGREDIENT_LOCKED_LABEL % ingredient.min_reputation if is_locked else ingredient.name)
			var new_item_index = get_item_count() - 1
			set_item_id(new_item_index, ingredient.id)
			set_item_disabled(new_item_index, is_locked)
			var tooltip : String = ingredient.description + "\n" + ingredient.get_stat_string() if not is_locked else StringContainer.INGREDIENT_LOCKED_LABEL % ingredient.min_reputation
			get_popup().set_item_tooltip(new_item_index, tooltip)


func _first_enabled_index() -> int:
	for i in range(item_count):
		if not is_item_disabled(i):
			return i
	return -1


func _on_item_selected(index: int) -> void:
	var selected_id = get_item_id(index)

	if selected_id != -1:
		_sync_own_tooltip(selected_id)
		GUISignals.active_ingredient_changed.emit(selected_id)


func _on_global_ingredient_changed(ingredient_id: int) -> void:
	var ingredient = IngredientDatabase.get_item_by_id(ingredient_id)

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


## Mirrors the popup's per-item tooltip onto the closed button itself, so
## hovering the collapsed dropdown (not just an open popup item) still shows
## ingredient info instead of requiring a click.
func _sync_own_tooltip(ingredient_id : int) -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient:
		tooltip_text = ingredient.description + "\n" + ingredient.get_stat_string()
