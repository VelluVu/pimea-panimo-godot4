class_name BuyMissingButton
extends TooltipButton

## "Buy what's missing" for the loaded recipe, with its price. Sits in both the shop and the
## brewery, so a recipe can be bought for without walking between them.

const BUY_MISSING_TEXT : String = "Osta puuttuvat"
const BUY_MISSING_PRICE_FORMAT : String = "Osta puuttuvat: %.2f €"
const BUY_MISSING_TOOLTIP : String = "Ostaa kerralla kaiken, mitä ladattu resepti vielä tarvitsee pöydän ja varaston lisäksi."


func _init(height : float) -> void:
	tooltip_text = BUY_MISSING_TOOLTIP
	custom_minimum_size.y = height
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func() -> void: GUISignals.buy_missing_for_recipe_requested.emit())


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	_update()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update()


## A locked or unaffordable buy stays pressable, so the tap can say why.
func _update() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	var to_buy : Dictionary = {}
	if brewery != null:
		to_buy = RecipeShopping.missing(brewery.brew_preparation.active_recipe_target, brewery.owned_ingredient_amounts())
	disabled = to_buy.is_empty()
	if to_buy.is_empty():
		text = BUY_MISSING_TEXT
		return
	var price : float = RecipeShopping.cost(to_buy, brewery.resolver.ingredient_table(), brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE))
	text = tr(BUY_MISSING_PRICE_FORMAT) % price
