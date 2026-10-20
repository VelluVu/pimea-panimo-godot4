@tool
extends McpTestSuite

## SaleReceiptEntry's summary line, shared by the receipt log rows and the sale flash toast.
## The full receipt is tested in test_receipt_text.gd.


func suite_name() -> String:
	return "sale_receipt_entry"


func test_get_summary_text_includes_style_and_bottle_count() -> void:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = "Kotikalja"
	var entry := SaleReceiptEntry.new()
	entry.breakdown = breakdown
	entry.bottles_sold = 3
	assert_eq(entry.get_summary_text(), "Kotikalja x3")
