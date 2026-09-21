class_name SaleBreakdown
extends Resource

## Cost and price of one bottle. No tax: the cellar remits nothing, so price is cost plus
## profit. See StylePricing.calculate_price_breakdown().

@export var style_name: String = ""
## Display only (labels, receipts); it does not affect price.
@export var abv: float = 0.0

@export var raw_cost_per_bottle: float = 0.0
@export var profit_per_bottle: float = 0.0
@export var price_per_bottle: float = 0.0
