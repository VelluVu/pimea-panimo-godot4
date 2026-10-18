class_name SaleReceiptEntry
extends Resource

## One sale, kept for the day's receipt log and sent as BrewerySignals.beer_sale_breakdown,
## so the flash toast formats it the same way.

@export var breakdown : SaleBreakdown
@export var bottles_sold : int = 0
@export var gross_income : float = 0.0
## Paid only when the quality beat this customer's bar.
@export var tip_income : float = 0.0
@export var net_income : float = 0.0
## For the glass colour; -1 on receipts saved before this field.
@export var beer_ebc : int = -1
## Above 1.0 when the batch sold at its aging premium (BrewBatch.get_aged_price_multiplier()).
@export var aged_price_multiplier : float = 1.0
## For the bartender's walk to its tap; not saved.
var batch : BrewBatch = null

const SUMMARY_FORMAT : String = "%s x%d"
const BREAKDOWN_FORMAT : String = "Raaka-aineet: %.2f €\nKate: %.2f €\n= Hinta/annos: %.2f €"
const TOTALS_FORMAT : String = "Myynti: +%.1f €\nTippi: +%.1f €\nTILILLE: +%.1f €"


func get_summary_text() -> String:
	return SUMMARY_FORMAT % [tr(breakdown.style_name), bottles_sold]


func get_breakdown_text() -> String:
	return tr(BREAKDOWN_FORMAT) % [
		breakdown.raw_cost_per_bottle,
		breakdown.profit_per_bottle,
		breakdown.price_per_bottle,
	]


func get_totals_text() -> String:
	return tr(TOTALS_FORMAT) % [gross_income, tip_income, net_income]
