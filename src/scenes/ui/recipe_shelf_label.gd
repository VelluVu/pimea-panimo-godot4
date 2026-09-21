class_name RecipeShelfLabel
extends Label

## Hover label for RecipeShelfHoverArea, matching BreweryEntrancePanel /
## ShopEntrancePanel's exact pattern: a self-contained component that
## listens to its own world-hover-area signal and shows/hides itself,
## rather than being driven by GUI.gd.

const LABEL_TEXT : String = "Reseptit"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_recipe_shelf_hover_area.connect(_on_mouse_entered_recipe_shelf_hover_area)


func _on_mouse_entered_recipe_shelf_hover_area(is_entered : bool) -> void:
	visible = is_entered
