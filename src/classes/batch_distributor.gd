class_name BatchDistributor
extends RefCounted

## Moves finished batches out of the warehouse without a walk-in customer:
## cheap bulk sell and shipping a keg to a BarContact. The payout math is static
## so it stays unit-testable without a live Brewery.

## Per-bottle payout for bulk-selling a batch (see _on_bulk_sell_batch_
## requested()) as a fraction of raw_cost_per_bottle — deliberately below
## 1.0 so even a peak-quality batch nets less than it cost to brew; it's a
## "clear the warehouse" release valve, not an alternate income source.
## current_quality is also clamped to 1.0 before this multiplies it, so a
## spoiled/declining batch (current_quality well under 1.0) pays out even
## less, potentially far under ingredient cost.
const BULK_SELL_RATE : float = 0.5

## Quality clamp range applied before BarContact.price_multiplier in
## ship_batch_to_bar() — a floor above 0.0 (unlike bulk-sell's) since a bar
## still expects the batch to be drinkable, and a ceiling above 1.0 (unlike
## bulk-sell's hard cap at 1.0) since a genuinely excellent batch is worth
## a real premium to a paying venue, not just "no worse than average".
const SHIP_TO_BAR_QUALITY_CLAMP_MIN : float = 0.3

const SHIP_TO_BAR_QUALITY_CLAMP_MAX : float = 1.3

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.bulk_sell_batch_requested.connect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.connect(_on_ship_batch_to_bar_requested)


## Must run before the owning Brewery is replaced, see Brewery.disconnect_signals().
func disconnect_signals() -> void:
	GUISignals.bulk_sell_batch_requested.disconnect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.disconnect(_on_ship_batch_to_bar_requested)


## Pure payout math for bulk-selling a batch, split out from
## _on_bulk_sell_batch_requested() so it's directly unit-testable without
## constructing a Brewery (which needs live autoloads — see _init()) —
## same "static function, instance method wraps it" split as
## BrewResolver.calculate_price_breakdown()/get_price_breakdown(). See
## BULK_SELL_RATE's docstring for why the result is deliberately
## underwater against raw_cost_per_bottle even at quality 1.0.
static func calculate_bulk_sell_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int) -> float:
	var quality_factor : float = clampf(quality, 0.0, 1.0)
	return snappedf(raw_cost_per_bottle * BULK_SELL_RATE * quality_factor * amount_bottles, 0.1)


## Dumps an entire batch for cheap warehouse-clearing cash instead of
## waiting for customers — see BULK_SELL_RATE's docstring for why the
## payout is deliberately underwater against what the batch cost to brew.
## No reputation/XP/tip and no risk change: unlike a real sale
## (CustomerManager.process_auto_sale()) this never reaches a customer at
## all, it's just inventory leaving the warehouse for money.
func _on_bulk_sell_batch_requested(batch : BrewBatch) -> void:
	if batch == null or not brewery.inventory.brew_batches.has(batch) or batch.amount_bottles <= 0:
		return

	var raw_cost_per_bottle : float = brewery.resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
	var payout : float = calculate_bulk_sell_payout(raw_cost_per_bottle, batch.current_quality, batch.amount_bottles)
	payout = snappedf(payout * brewery.stats.multiplier(PerkStats.DISTRIBUTION_INCOME), 0.1)

	brewery.money += payout
	BrewerySignals.batch_bulk_sold.emit(batch.get_style_name(), batch.amount_bottles, payout)

	brewery.inventory.brew_batches.erase(batch)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Pure payout math for shipping a batch to a BarContact — same "static
## twin of the instance handler" split as calculate_bulk_sell_payout()
## above, for the same reason (unit-testable without a live Brewery).
static func calculate_ship_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int, price_multiplier : float) -> float:
	var quality_factor : float = clampf(quality, SHIP_TO_BAR_QUALITY_CLAMP_MIN, SHIP_TO_BAR_QUALITY_CLAMP_MAX)
	return snappedf(raw_cost_per_bottle * price_multiplier * quality_factor * amount_bottles, 0.1)


## Hands an entire batch off to a BarContact instead of the counter — see
## SHIP_TO_BAR_QUALITY_CLAMP_MIN/MAX and BarContact.price_multiplier for
## the payout formula, and BarContact.risk_per_shipment for the trade-off:
## unlike _on_bulk_sell_batch_requested(), this raises risk since the
## batch is now circulating outside the player's own cellar. Silently
## refuses a bar the player's reputation hasn't unlocked yet — mirrors
## Brewery._on_buy_ingredient()'s locked-ingredient guard, and
## BarContactOptionButton disables locked contacts in the picker itself so
## a real player can't normally reach this path either.
func _on_ship_batch_to_bar_requested(batch : BrewBatch, bar : BarContact) -> void:
	if batch == null or bar == null or not brewery.inventory.brew_batches.has(batch) or batch.amount_bottles <= 0:
		return
	if brewery.reputation < bar.required_reputation:
		return

	var raw_cost_per_bottle : float = brewery.resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
	var payout : float = calculate_ship_payout(raw_cost_per_bottle, batch.current_quality, batch.amount_bottles, bar.price_multiplier)
	payout = snappedf(payout * brewery.stats.multiplier(PerkStats.DISTRIBUTION_INCOME), 0.1)

	brewery.money += payout
	brewery.add_risk(bar.risk_per_shipment)
	BrewerySignals.keg_shipped_to_bar.emit(batch.get_style_name(), bar.bar_name, batch.amount_bottles, payout, bar.risk_per_shipment)

	brewery.inventory.brew_batches.erase(batch)
	BrewerySignals.brewery_state_changed.emit(brewery)
