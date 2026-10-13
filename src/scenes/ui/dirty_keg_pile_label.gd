class_name DirtyKegPileLabel
extends Label

## Hover label for DirtyKegPile, same self-contained pattern as WarehouseLabel: listens
## to its own world-hover signal and shows or hides itself.

const LABEL_FORMAT : String = "Likaiset tynnyrit (%d)"


func _ready() -> void:
	hide()
	GUISignals.mouse_entered_dirty_keg_pile.connect(_on_mouse_entered_dirty_keg_pile)
	GUISignals.touch_hints_shown.connect(_on_touch_hints_shown)


func _on_mouse_entered_dirty_keg_pile(is_entered : bool, count : int) -> void:
	text = tr(LABEL_FORMAT) % count
	visible = is_entered and count > 0


func _on_touch_hints_shown(is_shown : bool) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	_on_mouse_entered_dirty_keg_pile(is_shown, 0 if brewery == null else brewery.inventory.dirty_keg_count())
