@tool
extends McpTestSuite

const MoneyLedgerScript := preload("res://src/brewery/money_ledger.gd")


func suite_name() -> String:
	return "money_ledger"


func test_record_sums_per_source_on_the_ten_cent_grid() -> void:
	var today : Dictionary = {}
	MoneyLedgerScript.record(today, MoneyLedgerScript.Source.SALES, 4.1)
	MoneyLedgerScript.record(today, MoneyLedgerScript.Source.SALES, 2.2)
	MoneyLedgerScript.record(today, MoneyLedgerScript.Source.INGREDIENTS, -3.0)
	assert_true(is_equal_approx(today[MoneyLedgerScript.Source.SALES], 6.3))
	assert_true(is_equal_approx(MoneyLedgerScript.net(today), 3.3))


func test_a_zero_change_leaves_no_entry() -> void:
	var today : Dictionary = {}
	MoneyLedgerScript.record(today, MoneyLedgerScript.Source.TIPS, 0.0)
	assert_true(today.is_empty())


func test_closing_a_day_keeps_only_the_last_days() -> void:
	var history : Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0]
	var today : Dictionary = {MoneyLedgerScript.Source.SALES: 10.0, MoneyLedgerScript.Source.BILLS: -4.0}
	var closed : Array[float] = MoneyLedgerScript.closed_day(today, history)
	assert_eq(closed, [2.0, 3.0, 4.0, 5.0, 6.0] as Array[float])
	assert_eq(history.size(), 5, "the input history is not changed")


func test_an_empty_day_closes_as_zero() -> void:
	assert_eq(MoneyLedgerScript.closed_day({}, [] as Array[float]), [0.0] as Array[float])
