class_name ChalkboardLabel
extends Label

## Hover label for ChalkboardHoverArea — see RecipeShelfLabel's docstring
## for the pattern this mirrors (same as BreweryEntrancePanel /
## ShopEntrancePanel): self-contained, listens to its own world-hover-area
## signal, shows/hides itself.

const LABEL_TEXT : String = "Tilastot"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_chalkboard_hover_area.connect(_on_mouse_entered_chalkboard_hover_area)


func _on_mouse_entered_chalkboard_hover_area(is_entered : bool) -> void:
	visible = is_entered
