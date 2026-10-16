class_name BarContact
extends Resource

## A bar the player can ship a finished batch to from the warehouse (BatchDistributor).
## Pays less than a counter sale, with no reputation, XP or tip, and every shipment adds
## LVV risk. Loaded from res://src/resources/bars/ by CustomerRegistry.

@export var bar_name : String = ""
@export_multiline var description : String = ""

## Multiplies a batch's raw_cost_per_bottle (BrewResolver.get_price_breakdown)
## for this bar's payout — see Brewery.ship_batch_to_bar() for the full
## formula. Should normally sit below the ~1.5x a real retail sale nets.
@export var price_multiplier : float = 0.8

## Added to Brewery.risk (via Brewery.add_risk()) once per shipment,
## regardless of how many bottles the batch holds.
@export var risk_per_shipment : int = 5

## Gates this contact out of BarContactOptionButton until the player's
## reputation clears it, mirroring IngredientData.min_reputation's
## locked-item treatment in IngredientOptionButton.
@export var required_reputation : int = 0


## Risk change of shipping an alcohol-free keg anywhere: a little relief, since the
## cellar looks like it brews the legal stuff.
const ALCOHOL_FREE_SHIPMENT_RISK : int = -3


## LVV risk of shipping a keg of `abv` here, see ALCOHOL_FREE_SHIPMENT_RISK.
func risk_for(abv : float) -> int:
	return ALCOHOL_FREE_SHIPMENT_RISK if abv <= BeerStyle.ALCOHOL_FREE_MAX_ABV else risk_per_shipment
