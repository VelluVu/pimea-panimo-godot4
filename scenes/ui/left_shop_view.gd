class_name ShopView
extends VBoxContainer

const AMOUNT_PRICE_FORMAT : String = "%d %s - %d €"

## Same "float off the right edge of the button" treatment
## BrewPreparationPanel uses for its "+X XP" popup at "Pane", applied here
## to a "-X €" popup at "Osta" (buy) — see BrewerySignals.ingredient_purchased.
const MONEY_POPUP_COLOR : Color = Color.RED
const MONEY_POPUP_FORMAT : String = "-%.1f €"
const MONEY_POPUP_DURATION_SECONDS : float = 1.8
const MONEY_POPUP_OFFSET : Vector2 = Vector2(6, 0)
const MONEY_POPUP_FLOAT_DISTANCE : float = 35.0

@onready var current_item_label : Label = $Panel/MarginContainer/IngredientSelectionElementList/IngredientTypeSelector/IngredientRow/CurrentItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = $Panel/MarginContainer/IngredientSelectionElementList/IngredientTypeSelector
@export var main_slider : Slider
@export var buy_button : Button
@export var sell_button : Button


var current_id: int = -1


func _ready() -> void:
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_on_ingredient_selected_globally)
	# Affordability (what _update_slider() below computes from) changes on
	# every purchase/sale, but previously only refreshed when an
	# ingredient was newly selected — a big sale finishing in the
	# background while browsing the shop wouldn't unlock a higher max
	# until the player reselected. Same fix as BrewingView's slider.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.ingredient_purchased.connect(_on_ingredient_purchased)
	# BrewingView's own IngredientOptionButton listens to this same
	# global active_ingredient_changed signal, so adding something to the
	# brew table over there leaves current_id here pointing at whatever
	# was last touched globally — reset to a known starting point (tab 0
	# = malt, first enabled item = Pilsner malt) every time this view is
	# actually opened. Same fix as BrewingView's tab reset.
	visibility_changed.connect(_on_visibility_changed)
	_update_label()


func _on_ingredient_selected_globally(id: int) -> void:
	current_id = id
	_update_slider()
	_update_label()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_slider()
	_update_label()


func _on_visibility_changed() -> void:
	if visible:
		ingredient_type_selector.reset_to_first_tab()


func _on_slider_changed(_value : float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return
	
	var ingredient = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return
	
	var player_money : float = BrewEngine.current_brewery.money
	var effective_price : float = ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)

	var max_affordable : int = 0
	if effective_price > 0:
		max_affordable = int(player_money / effective_price)

	var max_limit = min(max_affordable, 99)
	
	main_slider.max_value = max_limit
	main_slider.value = min(main_slider.value, max_limit)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	var effective_price : float = ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)
	var total_price : int = roundi(effective_price * main_slider.value)
	current_item_label.text = AMOUNT_PRICE_FORMAT % [int(main_slider.value), ingredient.get_unit_string(), total_price]


## Floats a "-X €" popup off the right edge of the "Osta" button — see
## BrewerySignals.ingredient_purchased and BrewPreparationPanel's
## equivalent "+X XP" popup at "Pane".
func _on_ingredient_purchased(cost : float) -> void:
	var popup := Label.new()
	popup.text = MONEY_POPUP_FORMAT % cost
	popup.modulate = MONEY_POPUP_COLOR

	buy_button.add_child(popup)
	popup.position = Vector2(buy_button.size.x, 0) + MONEY_POPUP_OFFSET

	var tween := create_tween().set_parallel(true)
	var target_pos := popup.position + Vector2(0, -MONEY_POPUP_FLOAT_DISTANCE)
	var target_color := popup.modulate
	target_color.a = 0.0

	tween.tween_property(popup, "position", target_pos, MONEY_POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, MONEY_POPUP_DURATION_SECONDS)

	tween.chain().tween_callback(popup.queue_free)


func _on_buy_button_pressed() -> void:
	if current_id == -1:
		return
	
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
	
	GUISignals.buy_ingredient.emit(final_id, final_amount)


func _on_sell_button_pressed() -> void:
	if current_id == -1:
		return
		
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
	
	GUISignals.sell_ingredient.emit(final_id, final_amount)
