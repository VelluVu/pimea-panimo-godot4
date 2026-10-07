@tool
extends McpTestSuite

const MoneyTextScript := preload("res://src/ui/money_text.gd")
const MoneyLedgerScript := preload("res://src/brewery/money_ledger.gd")


func suite_name() -> String:
	return "money_text"


func _today() -> Dictionary:
	return {
		MoneyLedgerScript.Source.SALES: 40.0,
		MoneyLedgerScript.Source.TIPS: 5.2,
		MoneyLedgerScript.Source.INGREDIENTS: -12.0,
		MoneyLedgerScript.Source.BILLS: -8.0,
	}


func test_the_tooltip_splits_today_into_income_and_costs() -> void:
	var text : String = MoneyTextScript.tooltip(200.0, _today(), [] as Array[float])
	assert_contains(text, "Rahaa 200.0 €")
	assert_contains(text, "Tänään +25.2 €")
	assert_contains(text, "myynti +40.0 €, tipit +5.2 €")
	assert_contains(text, "ainekset -12.0 €, laskut -8.0 €")


func test_a_fresh_run_has_no_yesterday_or_trend() -> void:
	var text : String = MoneyTextScript.tooltip(20.0, {}, [] as Array[float])
	assert_contains(text, "Tänään +0.0 €")
	assert_false(text.contains("Eilen"))
	assert_false(text.contains("Viime päivät"))


func test_the_trend_lists_the_closed_days_oldest_first() -> void:
	var text : String = MoneyTextScript.tooltip(200.0, {}, [12.4, 30.0, -20.0, 62.0, 45.2] as Array[float])
	assert_contains(text, "Eilen +45.2 €")
	assert_contains(text, "Viime päivät: +12  +30  -20  +62  +45")


func test_one_closed_day_shows_yesterday_without_a_trend() -> void:
	var text : String = MoneyTextScript.tooltip(200.0, {}, [8.0] as Array[float])
	assert_contains(text, "Eilen +8.0 €")
	assert_false(text.contains("Viime päivät"))
