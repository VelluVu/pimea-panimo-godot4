class_name ShopView
extends VBoxContainer

## The chosen amount and its price under the slider, then the unit price and the stock.
const AMOUNT_PRICE_FORMAT : String = "%s %s = %s"
const UNIT_PRICE_FORMAT : String = "%s / %s, varastossa %s %s"
const SLIDER_TOOLTIP_FORMAT : String = "Määrä (%s / %s)"
const BUY_TOOLTIP_FORMAT : String = "Osta valittu määrä (%s)"
const SELL_TOOLTIP : String = "Myy valittu määrä varastosta takaisin kauppaan"

## The "-X €" popup at "Osta", like the brew button's XP popup.
const MONEY_POPUP_COLOR : Color = Color.RED
## Why a purchase failed, floated from the same spot instead of a toast.
const LOCKED_POPUP_FORMAT : String = "Vaatii %d mainetta"
const UNDERFUNDED_POPUP_FORMAT : String = "Ei varaa: %s"
const NOT_IN_STOCK_TEXT : String = "Ei varastossa"
const NO_AMOUNT_TEXT : String = "Valitse määrä"
const QUICK_ADD_FORMAT : String = "+%s"
## Finger-sized, like the slider's - and + buttons and the brewery's rows.
const ROW_BUTTON_HEIGHT : float = 26.0

@onready var current_item_label : Label = %ShopItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = %ShopTypeSelector
@onready var header_label : Label = $Panel/MarginContainer/IngredientSelectionElementList/HeaderLabel
@export var main_slider : Slider
@export var buy_button : Button
@export var sell_button : Button


var current_id: int = -1
## Built at runtime under the slider: the quick amounts and "buy what's missing".
var _quick_row : HBoxContainer
var buy_missing_button : BuyMissingButton
## How many units the money buys right now; 0 makes "Osta" say why.
var _max_affordable : int = 0


func _ready() -> void:
	PanelHeader.wrap(header_label)
	var slider_row : HBoxContainer = SliderStepper.wrap(main_slider)
	_build_rows_under(slider_row)
	ingredient_type_selector.add_step_buttons()
	ingredient_type_selector.option_button.stock_covers_recipe = true
	main_slider.tooltip_text = tr(SLIDER_TOOLTIP_FORMAT) % [InputManager.get_binding_text(InputManager.ACTION_AMOUNT_UP), InputManager.get_binding_text(InputManager.ACTION_AMOUNT_DOWN)]
	buy_button.tooltip_text = tr(BUY_TOOLTIP_FORMAT) % InputManager.get_binding_text(InputManager.ACTION_INGREDIENT_CONFIRM)
	sell_button.tooltip_text = SELL_TOOLTIP
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_on_ingredient_selected_globally)
	# Affordability changes on every purchase or sale, not only on selecting an ingredient.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.ingredient_purchased.connect(_on_ingredient_purchased)
	BrewerySignals.ingredient_purchase_locked.connect(func(_name: String, required_reputation: int) -> void:
		FloatingText.reason(buy_button, tr(LOCKED_POPUP_FORMAT) % required_reputation))
	BrewerySignals.ingredient_purchase_underfunded.connect(func(_name: String, price: float, _money: float) -> void:
		FloatingText.reason(buy_button, tr(UNDERFUNDED_POPUP_FORMAT) % NumberText.money(price)))
	# BrewingView's selector fires the same signal, so reset to malt on each open.
	visibility_changed.connect(_on_visibility_changed)
	_update_label()


func _input(event : InputEvent) -> void:
	if IngredientViewKeys.handle(event, self, ingredient_type_selector, main_slider, _on_buy_button_pressed):
		get_viewport().set_input_as_handled()


func _on_ingredient_selected_globally(id: int) -> void:
	current_id = id
	_update_slider()
	# The last amount means nothing for another ingredient (25 g of hops is not 25 kg of
	# malt), so start from what the recipe is missing.
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient != null:
		main_slider.value = SuggestedAmount.for_shop(_missing_for_recipe().get(id, 0), _max_affordable, ingredient.amount_step())
	_update_label()
	_update_quick_row()


func _missing_for_recipe() -> Dictionary:
	var brewery : Brewery = BrewEngine.current_brewery
	return RecipeShopping.missing(brewery.brew_preparation.active_recipe_target, brewery.owned_ingredient_amounts())


func _in_stock() -> int:
	var item : InventoryItem = BrewEngine.current_brewery.inventory.get_item_by_id(current_id)
	return item.amount if item != null else 0


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_slider()
	_update_label()


## Pick the amount, read it, then act: slider, quick amounts, the amount line, Osta / Myy,
## and "buy what's missing" last.
func _build_rows_under(slider_row : HBoxContainer) -> void:
	var box : Node = slider_row.get_parent()
	var buttons_row : Node = buy_button.get_parent()
	_quick_row = HBoxContainer.new()
	buy_missing_button = BuyMissingButton.new(ROW_BUTTON_HEIGHT)
	box.add_child(_quick_row)
	current_item_label.reparent(box)
	current_item_label.size_flags_horizontal = Control.SIZE_FILL
	current_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_item_label.clip_text = false
	box.add_child(buy_missing_button)
	for row : Node in [slider_row, _quick_row, current_item_label, buttons_row, buy_missing_button]:
		box.move_child(row, -1)


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


## Opens on the first ingredient the loaded recipe is missing.
func _on_visibility_changed() -> void:
	if visible:
		var missing : Dictionary = _missing_for_recipe()
		ingredient_type_selector.select_ingredient(missing.keys()[0] if not missing.is_empty() else -1)


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

	_max_affordable = mini(max_affordable, ShopQuickAmounts.max_units(ingredient))
	# An empty range draws the knob at the far end, which reads as "full".
	main_slider.editable = _max_affordable > 0
	main_slider.max_value = maxi(_max_affordable, ingredient.amount_step())
	main_slider.value = mini(int(main_slider.value), _max_affordable)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	var effective_price : float = _unit_price(ingredient)
	var total_price : float = snappedf(effective_price * main_slider.value, 0.01)
	var unit : String = ingredient.get_unit_string()
	current_item_label.text = AMOUNT_PRICE_FORMAT % [ingredient.amount_text(int(main_slider.value)), unit, NumberText.money(total_price)]
	current_item_label.text += "\n" + tr(UNIT_PRICE_FORMAT) % [NumberText.money(effective_price), ingredient.get_pack_string(), ingredient.amount_text(_in_stock()), unit]


func _unit_price(ingredient : IngredientData) -> float:
	return ingredient.base_price * BrewEngine.current_brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE)


## Floats a "-X €" popup off the "Osta" button.
func _on_ingredient_purchased(cost : float) -> void:
	FloatingText.rise(buy_button, NumberText.signed_money(-cost), MONEY_POPUP_COLOR)


## A press that cannot buy or sell anything says why, instead of doing nothing.
func _on_buy_button_pressed() -> void:
	if current_id == -1:
		return
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if _max_affordable <= 0 and ingredient != null:
		FloatingText.reason(buy_button, tr(UNDERFUNDED_POPUP_FORMAT) % NumberText.money(_unit_price(ingredient)))
		return
	var final_amount : int = roundi(main_slider.value)
	if final_amount <= 0:
		FloatingText.reason(buy_button, tr(NO_AMOUNT_TEXT))
		return
	GUISignals.buy_ingredient.emit(current_id, final_amount)


func _on_sell_button_pressed() -> void:
	if current_id == -1:
		return
	if _in_stock() <= 0:
		FloatingText.reason(sell_button, tr(NOT_IN_STOCK_TEXT))
		return
	var final_amount : int = roundi(main_slider.value)
	if final_amount <= 0:
		FloatingText.reason(sell_button, tr(NO_AMOUNT_TEXT))
		return
	GUISignals.sell_ingredient.emit(current_id, final_amount)
