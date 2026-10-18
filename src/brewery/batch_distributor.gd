class_name BatchDistributor
extends RefCounted

## Ships a keg to a BarContact instead of selling it at the counter.

## Quality clamp for a bar's payout: drinkable beer at least, and up to
## BrewQuality.MAX_MULTIPLIER, so a fully tuned recipe is paid in full.
const SHIP_TO_BAR_QUALITY_CLAMP_MIN : float = 0.3

const SHIP_TO_BAR_QUALITY_CLAMP_MAX : float = 1.5

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.ship_batch_to_bar_requested.connect(_on_ship_batch_to_bar_requested)
	GUISignals.batch_hold_toggled.connect(_on_batch_hold_toggled)


func disconnect_signals() -> void:
	GUISignals.ship_batch_to_bar_requested.disconnect(_on_ship_batch_to_bar_requested)
	GUISignals.batch_hold_toggled.disconnect(_on_batch_hold_toggled)


## Static for tests.
static func calculate_ship_payout(wholesale_price_per_bottle : float, quality : float, amount_bottles : int, price_multiplier : float) -> float:
	var quality_factor : float = clampf(quality, SHIP_TO_BAR_QUALITY_CLAMP_MIN, SHIP_TO_BAR_QUALITY_CLAMP_MAX)
	return snappedf(wholesale_price_per_bottle * price_multiplier * quality_factor * amount_bottles, 0.1)


## Ships a whole batch to a bar the reputation has unlocked. Raises risk unless the beer is
## alcohol-free (BarContact.risk_for()).
func _on_ship_batch_to_bar_requested(batch : BrewBatch, bar : BarContact) -> void:
	if batch == null or bar == null or not brewery.inventory.brew_batches.has(batch) or batch.amount_bottles <= 0:
		return
	if brewery.reputation < bar.required_reputation:
		return

	var wholesale_price : float = brewery.resolver.get_wholesale_price_per_bottle(batch.beer_style)
	var payout : float = calculate_ship_payout(wholesale_price, batch.current_quality, batch.amount_bottles, bar.price_multiplier)
	payout = snappedf(payout * brewery.stats.multiplier(PerkStats.DISTRIBUTION_INCOME) * batch.get_aged_price_multiplier(), 0.1)

	brewery.change_money(payout, MoneyLedger.Source.SHIPMENTS)
	var risk : int = bar.risk_for(batch.get_abv())
	brewery.add_risk(risk)
	BrewerySignals.keg_shipped_to_bar.emit(batch.get_style_name(), bar.bar_name, batch.amount_bottles, payout, risk)

	brewery.inventory.remove_batch(batch)
	BrewerySignals.brewery_state_changed.emit(brewery)


func _on_batch_hold_toggled(batch : BrewBatch) -> void:
	if not brewery.inventory.brew_batches.has(batch):
		return
	batch.held = not batch.held
	BrewerySignals.brewery_state_changed.emit(brewery)
