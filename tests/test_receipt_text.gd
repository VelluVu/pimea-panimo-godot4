@tool
extends McpTestSuite

## ReceiptText: the receipt adds up from the list price to what went on the account.

const ReceiptTextScript := preload("res://src/ui/receipt_text.gd")
const NumberTextScript := preload("res://src/ui/number_text.gd")


func suite_name() -> String:
	return "receipt_text"


## Kotikalja's first brew: list 1.00 €, novelty +25 % sold at 1.30 € (rounded to 0.10).
func _make_entry() -> SaleReceiptEntry:
	var breakdown := SaleBreakdown.new()
	breakdown.style_name = "Kotikalja"
	breakdown.raw_cost_per_bottle = 0.36
	breakdown.profit_per_bottle = 0.64
	breakdown.price_per_bottle = 1.0
	var entry := SaleReceiptEntry.new()
	entry.breakdown = breakdown
	entry.bottles_sold = 3
	entry.charged_price = 1.3
	entry.novelty = true
	entry.gross_income = 3.9
	entry.tip_income = 1.5
	entry.net_income = 5.4
	entry.quality = 0.92
	entry.customer_title = "Raksamies"
	entry.receipt_number = 4
	entry.footer_index = 1
	return entry


func test_the_receipt_reads_from_list_price_to_the_account() -> void:
	var expected : String = "\n".join([
		"KUITTI #4",
		"Kotikalja, laatu 92 %",
		"Asiakas: Raksamies",
		ReceiptTextScript.SEPARATOR,
		"Raaka-aineet (arvio): " + NumberTextScript.money(0.36),
		"Kate: " + NumberTextScript.money(0.94),
		"Listahinta: " + NumberTextScript.money(1.0),
		"Uutuus: +25 %",
		"= Hinta/annos: " + NumberTextScript.money(1.3),
		ReceiptTextScript.SEPARATOR,
		"3 × %s = %s" % [NumberTextScript.money(1.3), NumberTextScript.money(3.9)],
		"Tippi: " + NumberTextScript.signed_money(1.5),
		"TILILLE: " + NumberTextScript.signed_money(5.4),
		ReceiptTextScript.SEPARATOR,
		ReceiptTextScript.FOOTERS[1],
	])
	assert_eq(ReceiptTextScript.text(_make_entry()), expected)


func test_each_counter_bonus_gets_its_own_line() -> void:
	var entry := _make_entry()
	entry.reputation_bonus = 0.1
	entry.perk_multiplier = 1.15
	entry.aged_price_multiplier = 1.2
	assert_eq(ReceiptTextScript.bonus_lines(entry), PackedStringArray(["Maine: +10 %", "Edut: +15 %", "Kypsytetty: +20 %", "Uutuus: +25 %"]))


func test_no_bonus_no_bonus_lines() -> void:
	var entry := _make_entry()
	entry.novelty = false
	assert_true(ReceiptTextScript.bonus_lines(entry).is_empty())


func test_the_tip_line_tells_a_doubled_tip_and_no_tip() -> void:
	var entry := _make_entry()
	assert_eq(ReceiptTextScript.tip_line(entry), "Tippi: " + NumberTextScript.signed_money(1.5))
	entry.tip_doubled = true
	assert_eq(ReceiptTextScript.tip_line(entry), "Tippi: %s (tuplana!)" % NumberTextScript.signed_money(1.5))
	entry.tip_income = 0.0
	assert_eq(ReceiptTextScript.tip_line(entry), "Tippi: ei tällä kertaa")


## Saved before the charged price and the extras were kept: list price, no header extras.
func test_an_old_receipt_falls_back_to_the_list_price() -> void:
	var entry := SaleReceiptEntry.new()
	entry.breakdown = _make_entry().breakdown
	entry.bottles_sold = 2
	entry.gross_income = 2.0
	entry.net_income = 2.0
	assert_eq(ReceiptTextScript.price_per_serving(entry), 1.0)
	var text : String = ReceiptTextScript.text(entry)
	assert_true(text.begins_with("Kotikalja\n"))
	assert_true(text.contains("2 × %s = %s" % [NumberTextScript.money(1.0), NumberTextScript.money(2.0)]))
	assert_false(text.contains("KUITTI"))
	assert_eq(ReceiptTextScript.footer_for(-1), "")
