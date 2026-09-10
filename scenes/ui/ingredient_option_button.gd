class_name IngredientOptionButton
extends OptionButton


@export var target_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT


func _ready() -> void:
	clip_text = true
	fit_to_longest_item = false

	while not IngredientDatabase.is_loaded:
		await get_tree().process_frame

	item_selected.connect(_on_item_selected)
	pressed.connect(_on_menu_opened)
	GUISignals.active_ingredient_changed.connect(_on_global_ingredient_changed)
	populate_ingredient_option_menu()


func _on_menu_opened() -> void:
	if item_count > 0:
		var popup: PopupMenu = get_popup()
		popup.set_focused_item(0)
		select(0)
		var first_id = get_item_id(0)
		
		if first_id != -1:
			GUISignals.active_ingredient_changed.emit(first_id)


func populate_ingredient_option_menu() -> void:
	clear()
	
	for id in IngredientDatabase.sorted_ids:
		var ingredient: IngredientData = IngredientDatabase.database[id]

		if ingredient.type == target_type:
			add_item(ingredient.name)
			var new_item_index = get_item_count() - 1
			set_item_id(new_item_index, ingredient.id)
			get_popup().set_item_tooltip(new_item_index, ingredient.description + "\n" + ingredient.get_stat_string())

	if get_item_count() > 0:
		select(0)
		# Deferred: this can run during _ready(), before ancestor views
		# (BrewingView/ShopView) have connected active_ingredient_changed —
		# emitting synchronously here would fire into the void and leave
		# their slider/label stuck uninitialized until the player manually
		# reselects. Deferring pushes it past the whole tree's _ready() pass.
		_on_item_selected.call_deferred(0)


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
		select(0)


## Mirrors the popup's per-item tooltip onto the closed button itself, so
## hovering the collapsed dropdown (not just an open popup item) still shows
## ingredient info instead of requiring a click.
func _sync_own_tooltip(ingredient_id : int) -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient:
		tooltip_text = ingredient.description + "\n" + ingredient.get_stat_string()
