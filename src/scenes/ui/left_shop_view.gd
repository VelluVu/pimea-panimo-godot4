class_name ShopView
extends VBoxContainer

const AMOUNT_PRICE_FORMAT : String = "%s %s - %d €"

## Same "float off the right edge of the button" treatment
## BrewPreparationPanel uses for its "+X XP" popup at "Pane", applied here
## to a "-X €" popup at "Osta" (buy) — see BrewerySignals.ingredient_purchased.
const MONEY_POPUP_COLOR : Color = Color.RED
const MONEY_POPUP_FORMAT : String = "-%.1f €"
const MONEY_POPUP_DURATION_SECONDS : float = 1.8
const MONEY_POPUP_OFFSET : Vector2 = Vector2(6, 0)
const MONEY_POPUP_FLOAT_DISTANCE : float = 35.0
## Why a purchase failed, floated from the same spot instead of a toast.
const LOCKED_POPUP_FORMAT : String = "Vaatii %d mainetta"
const UNDERFUNDED_POPUP_FORMAT : String = "Ei varaa: %d €"

@onready var current_item_label : Label = %ShopItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = %ShopTypeSelector
@onready var upgrades_button : Button = %UpgradesButton
@export var main_slider : Slider
@export var buy_button : Button
@export var sell_button : Button


var current_id: int = -1


func _ready() -> void:
	SliderStepper.wrap(main_slider)
	ingredient_type_selector.add_step_buttons(current_item_label)
	main_slider.value_changed.connect(_on_slider_changed)
	upgrades_button.pressed.connect(func() -> void: GUISignals.cellar_upgrades_requested.emit())
	GUISignals.active_ingredient_changed.connect(_on_ingredient_selected_globally)
	# Affordability changes on every purchase or sale, not only on selecting an ingredient.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.ingredient_purchased.connect(_on_ingredient_purchased)
	BrewerySignals.ingredient_purchase_locked.connect(func(_name: String, required_reputation: int) -> void:
		_float_popup(tr(LOCKED_POPUP_FORMAT) % required_reputation))
	BrewerySignals.ingredient_purchase_underfunded.connect(func(_name: String, price: int, _money: float) -> void:
		_float_popup(tr(UNDERFUNDED_POPUP_FORMAT) % price))
	# BrewingView's selector fires the same global signal, so reset to malt each time this
	# view opens.
	visibility_changed.connect(_on_visibility_changed)
	_update_label()


func _input(event : InputEvent) -> void:
	if IngredientViewKeys.handle(event, self, ingredient_type_selector, main_slider, _on_buy_button_pressed):
		get_viewport().set_input_as_handled()


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
	
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return
	
	var player_money : float = BrewEngine.current_brewery.money
	var effective_price : float = ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)

	var max_affordable : int = 0
	if effective_price > 0:
		max_affordable = int(player_money / effective_price)

	var max_limit: int = mini(max_affordable, 99)
	
	main_slider.max_value = max_limit
	main_slider.value = min(main_slider.value, max_limit)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	var effective_price : float = ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)
	var total_price : int = roundi(effective_price * main_slider.value)
	current_item_label.text = AMOUNT_PRICE_FORMAT % [ingredient.amount_text(int(main_slider.value)), ingredient.get_unit_string(), total_price]


## Floats a "-X €" popup off the right edge of the "Osta" button — see
## BrewerySignals.ingredient_purchased and BrewPreparationPanel's
## equivalent "+X XP" popup at "Pane".
func _on_ingredient_purchased(cost : float) -> void:
	_float_popup(MONEY_POPUP_FORMAT % cost)


func _float_popup(text : String) -> void:
	var popup := Label.new()
	popup.text = text
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
