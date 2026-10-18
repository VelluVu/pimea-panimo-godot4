class_name RecipeShelfLabel
extends Label

## Hover label for RecipeShelfHoverArea; shows and hides itself on its area's signal.

const LABEL_TEXT : String = "Reseptit"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_recipe_shelf_hover_area.connect(_on_mouse_entered_recipe_shelf_hover_area)
	GUISignals.touch_hints_shown.connect(_on_mouse_entered_recipe_shelf_hover_area)


func _on_mouse_entered_recipe_shelf_hover_area(is_entered : bool) -> void:
	visible = is_entered
