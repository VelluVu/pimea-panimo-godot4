@tool
extends McpTestSuite

## Unit tests for SaleReceiptEntry's pure text-formatting methods — the
## same strings SaleReceiptLogWindow and SaleFlashToast both read (see
## that class's own docstring: "one source of truth for how a sale's
## numbers are formatted, shared by both UIs"). No autoload dependency,
## so unlike Brewery/CustomerManager this is directly testable here.


func suite_name() -> String:
	return "sale_receipt_entry"


func _make_entry() -> SaleReceiptEntry:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = "Kotikalja"
	breakdown.abv = 3.5
	breakdown.raw_cost_per_bottle = 0.36
	breakdown.profit_per_bottle = 0.64
	breakdown.price_per_bottle = 1.0

	var entry := SaleReceiptEntry.new()
	entry.breakdown = breakdown
	entry.bottles_sold = 3
	entry.gross_income = 3.0
	entry.tip_income = 1.5
	entry.net_income = 4.5
	return entry


func test_get_summary_text_includes_style_and_bottle_count() -> void:
	var entry := _make_entry()
	assert_eq(entry.get_summary_text(), "Kotikalja x3")


func test_get_breakdown_text_formats_cost_profit_and_price() -> void:
	var entry := _make_entry()
	assert_eq(entry.get_breakdown_text(), "Raaka-aineet: 0.36 €\nKate: 0.64 €\n= Hinta/annos: 1.00 €")


func test_get_totals_text_formats_gross_tip_and_net() -> void:
	var entry := _make_entry()
	assert_eq(entry.get_totals_text(), "Myynti: +3.0 €\nTippi: +1.5 €\nTILILLE: +4.5 €")


## breakdown/totals use different precision (%.2f vs %.1f) — pin that down
## explicitly so a future edit can't quietly collapse them to the same
## rounding without a test noticing.
func test_breakdown_and_totals_use_different_decimal_precision() -> void:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = "IPA"
	breakdown.raw_cost_per_bottle = 1.234
	breakdown.profit_per_bottle = 0.876
	breakdown.price_per_bottle = 2.11

	var entry := SaleReceiptEntry.new()
	entry.breakdown = breakdown
	entry.bottles_sold = 1
	entry.gross_income = 2.111
	entry.tip_income = 0.0
	entry.net_income = 2.111

	assert_eq(entry.get_breakdown_text(), "Raaka-aineet: 1.23 €\nKate: 0.88 €\n= Hinta/annos: 2.11 €")
	assert_eq(entry.get_totals_text(), "Myynti: +2.1 €\nTippi: +0.0 €\nTILILLE: +2.1 €")
