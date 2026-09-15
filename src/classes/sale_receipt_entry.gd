class_name SaleReceiptEntry
extends Resource

## One completed sale, kept in Brewery.today_sale_receipts for the player
## to review at their own pace (the receipt library dropdown), cleared each
## day by TimeManager._advance_day(). Also the payload of
## BrewerySignals.beer_sale_breakdown, so the brief flash toast
## (SaleFlashToast) reads it too — one source of truth for how a sale's
## numbers are formatted, shared by both UIs.
##
## No tax_amount field: this cellar operation doesn't remit anything to
## the state, so there's nothing to split off gross_income at sale time —
## see SaleBreakdown and CustomerManager.process_auto_sale().

@export var breakdown : SaleBreakdown
@export var bottles_sold : int = 0
@export var gross_income : float = 0.0
## Untaxed gratuity, paid only when the batch's quality exceeded this
## customer's own expectations — see CustomerData.evaluate_brew_batch.
@export var tip_income : float = 0.0
@export var net_income : float = 0.0

const SUMMARY_FORMAT : String = "%s x%d"
const BREAKDOWN_FORMAT : String = "Raaka-aineet: %.2f €\nKate: %.2f €\n= Hinta/annos: %.2f €"
const TOTALS_FORMAT : String = "Myynti: +%.1f €\nTippi: +%.1f €\nTILILLE: +%.1f €"


func get_summary_text() -> String:
	return SUMMARY_FORMAT % [breakdown.style_name, bottles_sold]


func get_breakdown_text() -> String:
	return BREAKDOWN_FORMAT % [
		breakdown.raw_cost_per_bottle,
		breakdown.profit_per_bottle,
		breakdown.price_per_bottle,
	]


func get_totals_text() -> String:
	return TOTALS_FORMAT % [gross_income, tip_income, net_income]
