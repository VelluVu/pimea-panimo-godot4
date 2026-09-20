class_name BatchDistributor
extends RefCounted

## Moves finished batches out of the warehouse without a walk-in customer:
## cheap bulk sell and shipping a keg to a BarContact. The payout math is static
## so it stays unit-testable without a live Brewery.

## Bulk-sell payout as a fraction of raw cost. Below 1.0 on purpose: it clears the
## warehouse, it is not an income source. Quality is capped at 1.0, so spoiled
## batches pay even less.
const BULK_SELL_RATE : float = 0.5

## Quality clamp when shipping to a bar: a floor above 0 (bars expect drinkable
## beer) and a ceiling above 1.0 (an excellent batch earns a premium).
const SHIP_TO_BAR_QUALITY_CLAMP_MIN : float = 0.3

const SHIP_TO_BAR_QUALITY_CLAMP_MAX : float = 1.3

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.bulk_sell_batch_requested.connect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.connect(_on_ship_batch_to_bar_requested)


func disconnect_signals() -> void:
	GUISignals.bulk_sell_batch_requested.disconnect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.disconnect(_on_ship_batch_to_bar_requested)


## Static so the payout math can be unit-tested without a live Brewery.
static func calculate_bulk_sell_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int) -> float:
	var quality_factor : float = clampf(quality, 0.0, 1.0)
	return snappedf(raw_cost_per_bottle * BULK_SELL_RATE * quality_factor * amount_bottles, 0.1)


## Dumps a whole batch for cash without a customer: no reputation, XP, tip or risk.
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


## Static for the same reason as calculate_bulk_sell_payout().
static func calculate_ship_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int, price_multiplier : float) -> float:
	var quality_factor : float = clampf(quality, SHIP_TO_BAR_QUALITY_CLAMP_MIN, SHIP_TO_BAR_QUALITY_CLAMP_MAX)
	return snappedf(raw_cost_per_bottle * price_multiplier * quality_factor * amount_bottles, 0.1)


## Ships a whole batch to a bar. Raises risk, since the beer now circulates outside
## the cellar. Refuses a bar the player's reputation has not unlocked.
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
