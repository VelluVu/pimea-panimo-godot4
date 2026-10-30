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
	# Like the shipped upgrades: levels add up.
	upgrade.stacks_additively = true
	return upgrade


func test_pips_fill_the_owned_levels() -> void:
	assert_eq(TextScript.level_pips(2, 5), "■■□□□")
	assert_eq(TextScript.level_pips(0, 3), "□□□")
	assert_eq(TextScript.level_pips(5, 5), "■■■■■")


func test_button_shows_the_next_price_until_maxed() -> void:
	assert_eq(TextScript.button_text(_upgrade(), 0), "Osta 40 €")
	assert_eq(TextScript.button_text(_upgrade(), 5), TextScript.MAXED_TEXT)


func test_effect_change_shows_now_and_next() -> void:
	assert_eq(TextScript.effect_change(_upgrade(), 0), "Annossaanto kasvaa 0 % → 6 %")
	assert_eq(TextScript.effect_change(_upgrade(), 2), "Annossaanto kasvaa 12 % → 18 %")


func test_a_maxed_effect_shows_only_the_current_value() -> void:
	assert_eq(TextScript.effect_change(_upgrade(), 5), "Annossaanto kasvaa 30 %")


func test_buy_tooltip_says_why_the_button_is_grey() -> void:
	assert_eq(TextScript.buy_tooltip(_upgrade(), 0, 40.0), "", "affordable: no reason")
	assert_contains(TextScript.buy_tooltip(_upgrade(), 0, 12.5), "27")
	assert_eq(TextScript.buy_tooltip(_upgrade(), 5, 1000.0), TextScript.MAXED_TOOLTIP)


func test_kegs_get_their_own_line() -> void:
	var upgrade : CellarUpgradeData = UpgradeScript.new()
	upgrade.max_level = 8
	upgrade.kegs_per_level = 1
	assert_eq(TextScript.effect_change(upgrade, 2), "Tynnyreitä ja hanoja lisää: 2 → 3")
	assert_eq(TextScript.effect_change(upgrade, 8), "Tynnyreitä ja hanoja lisää: 8")


func test_a_machine_says_what_it_does_and_that_it_stays() -> void:
	var machine : CellarUpgradeData = UpgradeScript.new()
	machine.is_machine = true
	machine.machine_effect = "Pesee tyhjät tynnyrit itse."
	assert_eq(TextScript.machine_lines(machine, false), "Pesee tyhjät tynnyrit itse.
" + TextScript.MACHINE_BUY_ONCE_TEXT)
	assert_eq(TextScript.machine_lines(machine, true), "Pesee tyhjät tynnyrit itse.
" + TextScript.MACHINE_OWNED_TEXT)
