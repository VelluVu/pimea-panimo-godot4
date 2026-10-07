class_name ShopEntrancePanel
extends Panel

## The shop's door in the cellar. Newly unlocked ingredients float up from it as a short
## line (ToastText.ingredients_unlocked) instead of a toast, so the news points at where
## they can be bought.

const UNLOCK_POPUP_COLOR : Color = Color(0.55, 1.0, 0.55, 1)
const UNLOCK_POPUP_OUTLINE_COLOR : Color = Color(0.05, 0.1, 0.05, 1)
const UNLOCK_POPUP_OUTLINE_SIZE : int = 4
const UNLOCK_POPUP_RISE : float = 45.0
const UNLOCK_POPUP_SECONDS : float = 3.5

@onready var shop_button : Button = $ShopButton
@onready var shop_label : Label = $ShopLabel

var _unlock_tracker : ReputationUnlockTracker


func _ready() -> void:
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
		_float_unlock_popup(text)


## Rises from the top of the door and fades out over the way.
func _float_unlock_popup(text : String) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = UNLOCK_POPUP_COLOR
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_constant_override(&"outline_size", UNLOCK_POPUP_OUTLINE_SIZE)
	popup.add_theme_color_override(&"font_outline_color", UNLOCK_POPUP_OUTLINE_COLOR)
	add_child(popup)
	popup.reset_size()
	popup.position = Vector2((size.x - popup.size.x) / 2.0, -popup.size.y)

	var faded : Color = UNLOCK_POPUP_COLOR
	faded.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - UNLOCK_POPUP_RISE, UNLOCK_POPUP_SECONDS)
	# Readable for most of the rise, then gone.
	tween.tween_property(popup, "modulate", faded, UNLOCK_POPUP_SECONDS * 0.4).set_delay(UNLOCK_POPUP_SECONDS * 0.6)
	tween.chain().tween_callback(popup.queue_free)


func _on_shop_button_mouse_entered() -> void:
	shop_button.modulate = Color.GOLD
	shop_label.show()
	GUISignals.mouse_entered_shop_hover_area.emit(true)


func _on_shop_button_mouse_exited() -> void:
	shop_button.modulate = Color.WHITE
	shop_label.hide()
	GUISignals.mouse_entered_shop_hover_area.emit(false)
