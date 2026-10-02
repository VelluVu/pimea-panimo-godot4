@tool
extends McpTestSuite

## Unit tests for CellarUpgradeText.

const TextScript := preload("res://src/ui/cellar_upgrade_text.gd")
const UpgradeScript := preload("res://src/brewery/cellar_upgrade_data.gd")


func suite_name() -> String:
	return "cellar_upgrade_text"


func _upgrade() -> CellarUpgradeData:
	var upgrade : CellarUpgradeData = UpgradeScript.new()
	upgrade.perk_name = "Isompi käymisastia"
	upgrade.max_level = 5
	upgrade.base_cost = 40
	upgrade.cost_growth = 1.7
	upgrade.brew_yield_multiplier = 1.06
	return upgrade


func test_title_shows_the_level() -> void:
	assert_eq(TextScript.title_line(_upgrade(), 2), "Isompi käymisastia  2/5")


func test_button_shows_the_next_price_until_maxed() -> void:
	assert_eq(TextScript.button_text(_upgrade(), 0), "Osta 40 €")
	assert_eq(TextScript.button_text(_upgrade(), 5), TextScript.MAXED_TEXT)


func test_effect_lines_show_now_and_next() -> void:
	var lines : String = TextScript.effect_lines(_upgrade(), 0)
	assert_contains(lines, TextScript.NONE_TEXT)
	assert_contains(lines, "+6")
	assert_false(TextScript.effect_lines(_upgrade(), 5).contains("Seuraava"), "no next line when maxed")
