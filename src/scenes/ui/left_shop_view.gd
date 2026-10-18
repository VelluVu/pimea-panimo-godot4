class_name ShopView
extends VBoxContainer

const AMOUNT_PRICE_FORMAT : String = "%s %s - %.2f €"

## The "-X €" popup at "Osta", like the brew button's XP popup.
const MONEY_POPUP_COLOR : Color = Color.RED
const MONEY_POPUP_FORMAT : String = "-%.1f €"
const MONEY_POPUP_DURATION_SECONDS : float = 1.8
const MONEY_POPUP_OFFSET : Vector2 = Vector2(6, 0)
const MONEY_POPUP_FLOAT_DISTANCE : float = 35.0
## Why a purchase failed, floated from the same spot instead of a toast.
const LOCKED_POPUP_FORMAT : String = "Vaatii %d mainetta"
const UNDERFUNDED_POPUP_FORMAT : String = "Ei varaa: %.2f €"
const QUICK_ADD_FORMAT : String = "+%s"
const BUY_MISSING_TEXT : String = "Osta puuttuvat"
const BUY_MISSING_PRICE_FORMAT : String = "Osta puuttuvat: %.2f €"
const BUY_MISSING_TOOLTIP : String = "Ostaa kerralla kaiken, mitä ladattu resepti vielä tarvitsee pöydän ja varaston lisäksi."
## Finger-sized, like the slider's - and + buttons.
const ROW_BUTTON_HEIGHT : float = 24.0

@onready var current_item_label : Label = %ShopItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = %ShopTypeSelector
@onready var upgrades_button : Button = %UpgradesButton
@export var main_slider : Slider
@export var buy_button : Button
@export var sell_button : Button


var current_id: int = -1
## Built at runtime under the slider: the quick amounts and "buy what's missing".
var _quick_row : HBoxContainer
var _buy_missing_button : Button


func _ready() -> void:
	var slider_row : HBoxContainer = SliderStepper.wrap(main_slider)
	_build_rows_under(slider_row)
	ingredient_type_selector.add_step_buttons(current_item_label)
	main_slider.value_changed.connect(_on_slider_changed)
	upgrades_button.pressed.connect(func() -> void: GUISignals.cellar_upgrades_requested.emit())
	GUISignals.active_ingredient_changed.connect(_on_ingredient_selected_globally)
	# Affordability changes on every purchase or sale, not only on selecting an ingredient.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.ingredient_purchased.connect(_on_ingredient_purchased)
	BrewerySignals.ingredient_purchase_locked.connect(func(_name: String, required_reputation: int) -> void:
		_float_popup(tr(LOCKED_POPUP_FORMAT) % required_reputation))
	BrewerySignals.ingredient_purchase_underfunded.connect(func(_name: String, price: float, _money: float) -> void:
		_float_popup(tr(UNDERFUNDED_POPUP_FORMAT) % price))
	# BrewingView's selector fires the same signal, so reset to malt on each open.
	visibility_changed.connect(_on_visibility_changed)
	_update_label()


func _input(event : InputEvent) -> void:
	if IngredientViewKeys.handle(event, self, ingredient_type_selector, main_slider, _on_buy_button_pressed):
		get_viewport().set_input_as_handled()


func _on_ingredient_selected_globally(id: int) -> void:
	current_id = id
	# The last amount means nothing for another ingredient (25 g of hops is not 25 kg of malt).
	main_slider.value = 0
	_update_slider()
	_update_label()
	_update_quick_row()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_slider()
	_update_label()
	_update_buy_missing_button()


func _build_rows_under(slider_row : HBoxContainer) -> void:
	var box : Node = slider_row.get_parent()
	_quick_row = HBoxContainer.new()
	box.add_child(_quick_row)
	box.move_child(_quick_row, slider_row.get_index() + 1)
	_buy_missing_button = TooltipButton.new()
	_buy_missing_button.tooltip_text = BUY_MISSING_TOOLTIP
	_buy_missing_button.custom_minimum_size.y = ROW_BUTTON_HEIGHT
	_buy_missing_button.focus_mode = Control.FOCUS_NONE
	_buy_missing_button.pressed.connect(func() -> void: GUISignals.buy_missing_for_recipe_requested.emit())
	box.add_child(_buy_missing_button)
	box.move_child(_buy_missing_button, _quick_row.get_index() + 1)
	_update_buy_missing_button()


## One button per quick amount of the selected ingredient, each adding to the slider.
func _update_quick_row() -> void:
	for button : Node in _quick_row.get_children():
		button.queue_free()
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return
	for step : int in ShopQuickAmounts.steps(ingredient):
		var button := Button.new()
		button.text = QUICK_ADD_FORMAT % ingredient.amount_text(step)
		button.custom_minimum_size.y = ROW_BUTTON_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: main_slider.value = minf(main_slider.value + step, main_slider.max_value))
		_quick_row.add_child(button)


## What the loaded recipe still lacks, with its price. A locked or unaffordable buy stays
## pressable, so the tap can say why.
func _update_buy_missing_button() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	var to_buy : Dictionary = {}
	if brewery != null:
		to_buy = RecipeShopping.missing(brewery.brew_preparation.active_recipe_target, brewery.owned_ingredient_amounts())
	_buy_missing_button.disabled = to_buy.is_empty()
	if to_buy.is_empty():
		_buy_missing_button.text = BUY_MISSING_TEXT
		return
	var price : float = RecipeShopping.cost(to_buy, brewery.resolver.ingredient_table(), brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE))
	_buy_missing_button.text = tr(BUY_MISSING_PRICE_FORMAT) % price


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
	
	main_slider.step = ingredient.amount_step()
	var player_money : float = BrewEngine.current_brewery.money
	var effective_price : float = ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)

	var max_affordable : int = 0
	if effective_price > 0:
		max_affordable = int(player_money / effective_price)

	var max_limit: int = mini(max_affordable, ShopQuickAmounts.max_units(ingredient))
	
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
	var total_price : float = snappedf(effective_price * main_slider.value, 0.01)
	current_item_label.text = AMOUNT_PRICE_FORMAT % [ingredient.amount_text(int(main_slider.value)), ingredient.get_unit_string(), total_price]


## Floats a "-X €" popup off the "Osta" button.
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
