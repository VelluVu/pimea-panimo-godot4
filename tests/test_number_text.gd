@tool
extends McpTestSuite

const NumberTextScript := preload("res://src/ui/number_text.gd")


func suite_name() -> String:
	return "number_text"


func test_finnish_decimals_use_a_comma() -> void:
	assert_eq(NumberTextScript.decimal(3.14159, 1, ","), "3,1")
	assert_eq(NumberTextScript.decimal(3.14159, 1, "."), "3.1")


func test_money_always_shows_cents() -> void:
	assert_eq(NumberTextScript.money(20.0, ","), "20,00 €")
	assert_eq(NumberTextScript.money(8.5, "."), "8.50 €")


func test_a_money_change_carries_its_sign() -> void:
	assert_eq(NumberTextScript.signed_money(-8.0, ","), "-8,00 €")
	assert_eq(NumberTextScript.signed_money(12.25, ","), "+12,25 €")
