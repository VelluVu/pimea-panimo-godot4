@tool
extends McpTestSuite

## SpecialEventText: the delivery line and the reward popup numbers.


func suite_name() -> String:
	return "special_event_text"


func test_delivery_shows_what_is_asked_and_what_is_in_stock() -> void:
	assert_eq(SpecialEventText.delivery("Hefeweizen", 4, 15), "Toimita 15 × Hefeweizen.\nVarastossa: 4 / 15")


func test_delivery_caps_the_stock_at_what_is_asked() -> void:
	assert_eq(SpecialEventText.delivery("IPA", 40, 5), "Toimita 5 × IPA.\nVarastossa: 5 / 5")


func test_money_drops_the_decimal_of_whole_euros() -> void:
	assert_eq(SpecialEventText.money(90.0), "+90 €")
	assert_eq(SpecialEventText.money(-60.0), "-60 €")
	assert_eq(SpecialEventText.money(12.5), "+12.5 €")


func test_reputation_and_risk_carry_their_sign() -> void:
	assert_eq(SpecialEventText.reputation(8), "+8 mainetta")
	assert_eq(SpecialEventText.risk(-20), "-20 LVV-riskiä")
