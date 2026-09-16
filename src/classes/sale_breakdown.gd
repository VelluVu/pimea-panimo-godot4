class_name SaleBreakdown
extends Resource

## No excise duty or VAT: this cellar operation isn't remitting anything to
## the state (that's the entire point of hiding from LVV), so the price
## customers pay is exactly what it costs to make plus a profit margin —
## no tax markup, no "tax vs. net" split at sale time. See
## BrewResolver.calculate_price_breakdown().

@export var style_name: String = ""
## Still tracked (and still shown on labels/receipts) even though it no
## longer factors into price at all — it's a real attribute of the beer,
## just not a taxable one here.
@export var abv: float = 0.0

@export var raw_cost_per_bottle: float = 0.0
@export var profit_per_bottle: float = 0.0
@export var price_per_bottle: float = 0.0
