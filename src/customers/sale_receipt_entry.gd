class_name SaleReceiptEntry
extends Resource

## One sale, kept for the day's receipt log (see ReceiptText) and sent as
## BrewerySignals.beer_sale_breakdown.

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
## One serving's price after every bonus; -1 on receipts saved before this field.
@export var charged_price : float = -1.0
@export var reputation_bonus : float = 0.0
@export var perk_multiplier : float = 1.0
@export var novelty : bool = false
@export var tip_doubled : bool = false
@export var quality : float = -1.0
@export var customer_title : String = ""
## The day's running number, from 1.
@export var receipt_number : int = 0
## Which ReceiptText footer it ends with; -1 for none.
@export var footer_index : int = -1
## For the bartender's walk to its tap; not saved.
var batch : BrewBatch = null

const SUMMARY_FORMAT : String = "%s x%d"


func get_summary_text() -> String:
	return SUMMARY_FORMAT % [tr(breakdown.style_name), bottles_sold]
