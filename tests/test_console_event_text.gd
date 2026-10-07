@tool
extends McpTestSuite

const ConsoleEventTextScript := preload("res://src/ui/console_event_text.gd")


func suite_name() -> String:
	return "console_event_text"


func test_a_sale_line_has_every_part() -> void:
	var text : String = ConsoleEventTextScript.sale("Opiskelija", 2, "IPA", 6.0, 1.2, PopupTierRules.Tier.NORMAL, 3, 12)
	assert_eq(text, "Myynti: Opiskelija osti 2 × IPA, +6.0 €, tippi +1.2 €, mainetta +3, XP +12")


func test_a_plain_sale_skips_the_missing_parts() -> void:
	var text : String = ConsoleEventTextScript.sale("Raksamies", 1, "Kotikalja", 3.0, 0.0, PopupTierRules.Tier.NORMAL, 0, 0)
	assert_eq(text, "Myynti: Raksamies osti 1 × Kotikalja, +3.0 €")


func test_loud_tips_are_marked() -> void:
	assert_contains(ConsoleEventTextScript.sale("A", 1, "B", 3.0, 9.0, PopupTierRules.Tier.CRITICAL, 0, 0), "tippi +9.0 € (kriittinen!)")
	assert_contains(ConsoleEventTextScript.sale("A", 1, "B", 3.0, 2.0, PopupTierRules.Tier.BIG, 0, 0), "tippi +2.0 € (iso)")


func test_a_customer_turned_away_shows_the_reputation_loss() -> void:
	assert_eq(ConsoleEventTextScript.turned_away("Hipsteri", -2), "Hipsteri lähti tyhjin käsin, mainetta -2")


func test_a_named_list_joins_every_name() -> void:
	assert_eq(ConsoleEventTextScript.named_list("Uusia: %s", ["A", "B", "C"] as Array[String]), "Uusia: A, B, C")
