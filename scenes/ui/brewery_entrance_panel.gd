class_name BreweryEntrancePanel
extends Panel


@onready var brewery_label : Label = $BreweryLabel


func _ready() -> void:
	GUISignals.mouse_entered_brewery_hover_area.connect(_on_mouse_entered_brewery_hover_area)
	brewery_label.hide()


func _on_mouse_entered_brewery_hover_area(is_entered: bool) -> void:
	if is_entered:
		brewery_label.show()
	else:
		brewery_label.hide()