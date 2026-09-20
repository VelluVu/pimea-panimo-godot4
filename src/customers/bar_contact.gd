class_name BarContact
extends Resource

## A distribution outlet the player can ship a finished BrewBatch to from
## the warehouse view — see Brewery.ship_batch_to_bar(). Sits between
## Brewery.bulk_sell_batch()'s fire-sale (cheap, zero risk, no reputation
## needed) and a real customer sale at the counter (full retail price,
## plus reputation/XP/tip, zero LVV risk): a bar pays better than dumping
## stock, but every shipment adds LVV risk since it's product moving
## outside the player's own cellar. Loaded from res://src/resources/bars/
## by CustomerRegistry, the same folder-scan pattern it already uses for
## CustomerData/SpecialEventData/GroupVisitEventData.

@export var bar_name : String = ""
@export_multiline var description : String = ""

## Multiplies a batch's raw_cost_per_bottle (BrewResolver.get_price_breakdown)
## for this bar's payout — see Brewery.ship_batch_to_bar() for the full
## formula. Kept in the same "multiple of raw cost" unit as
## Brewery.BULK_SELL_RATE so the two payouts are directly comparable while
## tuning: BULK_SELL_RATE is fixed at 0.5, a bar contact should normally
## sit above that but below the ~1.5x a real retail sale nets.
@export var price_multiplier : float = 0.8

## Added to Brewery.risk (via Brewery.add_risk()) once per shipment,
## regardless of how many bottles the batch holds — the cost side of this
## bar's better-than-bulk-sell payout.
@export var risk_per_shipment : int = 5

## Gates this contact out of BarContactOptionButton until the player's
## reputation clears it, mirroring IngredientData.min_reputation's
## locked-item treatment in IngredientOptionButton.
@export var required_reputation : int = 0
