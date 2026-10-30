class_name SuggestedAmount
extends RefCounted

## Where the brewery and shop sliders start when an ingredient is picked: what the loaded
## recipe still needs, else one step. A slider at 0 made "Lisää" and "Osta" do nothing.


## For the brewing table: the recipe's shortfall on the table, limited by the stock.
static func for_table(needed : int, on_table : int, in_stock : int, step : int) -> int:
	var short : int = needed - on_table
	return mini(short if short > 0 else step, in_stock)


## For the shop: what the recipe is missing altogether, limited by what the money buys.
static func for_shop(missing : int, affordable : int, step : int) -> int:
	return mini(missing if missing > 0 else step, affordable)
