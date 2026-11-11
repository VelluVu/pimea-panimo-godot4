class_name RecipeShelfHoverArea
extends CounterHoverArea

## Hover-and-glow trigger for the recipe library, a wall shelf of bottles.


## The warehouse view lies over the shelf, so it takes no hover meanwhile.
func _connect_covering_views() -> void:
	GUISignals.warehouse_view_opened.connect(_set_covered.bind(true))
	GUISignals.warehouse_view_closed.connect(_set_covered.bind(false))


func _hover_changed(is_entered : bool) -> void:
	GUISignals.mouse_entered_recipe_shelf_hover_area.emit(is_entered)


func _clicked() -> void:
	GUISignals.recipe_library_requested.emit()
