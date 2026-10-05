class_name BankruptcyRules
extends RefCounted

## When a run is truly lost: no bottles and no way to brew even one known recipe.
## Brewing itself needs no cash (labels may push money below zero), so owned
## ingredients count, and so does what selling the rest back would raise.


static func is_bankrupt(money : float, bottles : int, owned : Dictionary, recipes : Array[Dictionary], buy_prices : Dictionary, sell_prices : Dictionary) -> bool:
	if bottles > 0 or money > 0.0:
		return false
	for recipe : Dictionary in recipes:
		if can_brew(money, owned, recipe, buy_prices, sell_prices):
			return false
	return true


## `owned` and `recipe` map ingredient id -> amount. `buy_prices` holds only the
## ingredients the player may buy now; `sell_prices` covers everything owned.
static func can_brew(money : float, owned : Dictionary, recipe : Dictionary, buy_prices : Dictionary, sell_prices : Dictionary) -> bool:
	var missing_cost : float = 0.0
	for id : int in recipe:
		var missing : int = maxi(0, recipe[id] - owned.get(id, 0))
		if missing == 0:
			continue
		if not buy_prices.has(id):
			return false
		missing_cost += missing * buy_prices[id]
	if missing_cost <= 0.0:
		return true

	var sell_back : float = 0.0
	for id : int in owned:
		var spare : int = owned[id] - recipe.get(id, 0)
		if spare > 0:
			sell_back += spare * sell_prices.get(id, 0.0)
	return money + sell_back >= missing_cost
