class_name BarContact
extends Resource

## A bar a finished batch can be shipped to (BatchDistributor): pays less than the
## counter, with no reputation, XP or tip, and each shipment adds LVV risk.

@export var bar_name : String = ""
@export_multiline var description : String = ""

## Multiplies the wholesale price (StylePricing.wholesale_price_per_bottle()) for this
## bar's payout.
@export var price_multiplier : float = 0.8

## Added to the LVV risk once per shipment, however full the keg.
@export var risk_per_shipment : int = 5

## Reputation the bar needs before it takes kegs; locked bars show disabled, like locked
## ingredients.
@export var required_reputation : int = 0


## Risk change of shipping an alcohol-free keg anywhere: a little relief, since the
## cellar looks like it brews the legal stuff.
const ALCOHOL_FREE_SHIPMENT_RISK : int = -3


## LVV risk of shipping a keg of `abv` here, see ALCOHOL_FREE_SHIPMENT_RISK.
func risk_for(abv : float) -> int:
	return ALCOHOL_FREE_SHIPMENT_RISK if abv <= BeerStyle.ALCOHOL_FREE_MAX_ABV else risk_per_shipment
