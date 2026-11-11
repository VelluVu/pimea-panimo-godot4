class_name DirtyKegPileLabel
extends Label

## Hover label for DirtyKegPile; shows and hides itself on its area's signal.

const LABEL_FORMAT : String = "Likaiset tynnyrit (%d)"

var _brewery : Brewery = null


func _ready() -> void:
	hide()
	GUISignals.mouse_entered_dirty_keg_pile.connect(_on_mouse_entered_dirty_keg_pile)
	GUISignals.touch_hints_shown.connect(_on_touch_hints_shown)


## GUI calls this on every new run or loaded save.
func bind_brewery(brewery : Brewery) -> void:
	_brewery = brewery


func _on_mouse_entered_dirty_keg_pile(is_entered : bool, count : int) -> void:
	text = tr(LABEL_FORMAT) % count
	visible = is_entered and count > 0


func _on_touch_hints_shown(is_shown : bool) -> void:
	_on_mouse_entered_dirty_keg_pile(is_shown, 0 if _brewery == null else _brewery.inventory.dirty_keg_count())
