class_name ShopEntrancePanel
extends Panel

## The shop's door in the cellar. New ingredients float up from it as a short line, so the
## news points at where they are bought.

const UNLOCK_POPUP_COLOR : Color = Color(0.55, 1.0, 0.55, 1)

@onready var shop_button : Button = $ShopButton
@onready var shop_label : Label = $ShopLabel

var _unlock_tracker : ReputationUnlockTracker
## The warehouse view lies over the shop door, so the door ignores the mouse meanwhile.
var _warehouse_open : bool = false


func _ready() -> void:
	shop_button.mouse_entered.connect(_on_shop_button_mouse_entered)
	GUISignals.touch_hints_shown.connect(func(is_shown : bool) -> void: shop_label.visible = is_shown)
	shop_button.mouse_exited.connect(_on_shop_button_mouse_exited)
	shop_label.hide()
	_reset_unlock_tracker(BrewEngine.current_brewery)
	BrewEngine.brewery_changed.connect(_reset_unlock_tracker)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	GUISignals.warehouse_view_opened.connect(_set_warehouse_open.bind(true))
	GUISignals.warehouse_view_closed.connect(_set_warehouse_open.bind(false))


func activate_shop_panel() -> void:
	shop_button.disabled = false
	shop_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if _warehouse_open else Control.MOUSE_FILTER_STOP


func _set_warehouse_open(is_open : bool) -> void:
	_warehouse_open = is_open
	if is_open:
		_on_shop_button_mouse_exited()
	if not shop_button.disabled:
		activate_shop_panel()


## A new or loaded run starts from its own reputation, so nothing it had is announced.
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
