class_name IngredientPrice
extends RefCounted

## What an ingredient costs in the shop and pays back when sold. `multiplier` is the shop
## perk, Brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE).

## Selling back never returns the full buy price.
const SELL_BACK_RATE : float = 0.75


## One pack or unit, as the shop shows it.
static func unit(ingredient : IngredientData, multiplier : float) -> float:
	return ingredient.base_price * multiplier


static func unit_sell(ingredient : IngredientData, multiplier : float) -> float:
	return unit(ingredient, multiplier) * SELL_BACK_RATE


## Rounded to the cent, as the money changes hands.
static func buy(ingredient : IngredientData, amount : int, multiplier : float) -> float:
	return snappedf(ingredient.base_price * amount * multiplier, 0.01)


static func sell(ingredient : IngredientData, amount : int, multiplier : float) -> float:
	return snappedf(amount * ingredient.base_price * multiplier * SELL_BACK_RATE, 0.01)
