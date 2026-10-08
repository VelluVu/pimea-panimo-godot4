class_name ShopEntrancePanel
extends Panel

## The shop's door in the cellar. Newly unlocked ingredients float up from it as a short
## line (ToastText.ingredients_unlocked) instead of a toast, so the news points at where
## they can be bought.

const UNLOCK_POPUP_COLOR : Color = Color(0.55, 1.0, 0.55, 1)

@onready var shop_button : Button = $ShopButton
@onready var shop_label : Label = $ShopLabel

var _unlock_tracker : ReputationUnlockTracker


func _ready() -> void:
	shop_button.add_to_group(TouchHints.GROUP)
	shop_button.mouse_entered.connect(_on_shop_button_mouse_entered)
	shop_button.mouse_exited.connect(_on_shop_button_mouse_exited)
	shop_label.hide()
	_reset_unlock_tracker(BrewEngine.current_brewery)
	BrewEngine.brewery_changed.connect(_reset_unlock_tracker)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func deactivate_shop_panel() -> void:
	shop_button.disabled = true
	shop_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func activate_shop_panel() -> void:
	shop_button.disabled = false
	shop_button.mouse_filter = Control.MOUSE_FILTER_STOP


## A new or loaded run starts from its own reputation, so nothing it already had is
## announced as new.
func _reset_unlock_tracker(brewery : Brewery) -> void:
	_unlock_tracker = ReputationUnlockTracker.new(brewery.reputation if brewery != null else 0)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	var text : String = ToastText.ingredients_unlocked(_unlock_tracker.update(brewery.reputation))
	if not text.is_empty():
		GUISignals.world_popup_requested.emit(text, UNLOCK_POPUP_COLOR, global_position + Vector2(size.x / 2.0, 0.0))


func _on_shop_button_mouse_entered() -> void:
	shop_button.modulate = Color.GOLD
	shop_label.show()
	GUISignals.mouse_entered_shop_hover_area.emit(true)


func _on_shop_button_mouse_exited() -> void:
	shop_button.modulate = Color.WHITE
	shop_label.hide()
	GUISignals.mouse_entered_shop_hover_area.emit(false)
