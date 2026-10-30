@tool
extends McpTestSuite

## Unit tests for OlutoppiText: the node tooltips.

const OlutoppiTextScript := preload("res://src/ui/olutoppi_text.gd")


func suite_name() -> String:
	return "olutoppi_text"


func _make_unlock() -> MetaUnlockData:
	var unlock := MetaUnlockData.new()
	unlock.perk_name = "Testiperkki"
	unlock.description = "Kuvaus"
	unlock.max_level = 3
	unlock.renown_cost_per_level = 25
	unlock.quality_bonus = 0.05 # per level
	return unlock


func test_locked_tooltip_lists_every_prerequisite_for_an_all_mode_node() -> void:
	var text : String = OlutoppiTextScript.locked_tooltip(_make_unlock(), PackedStringArray(["A", "B"]))
	assert_true(text.contains("A, B"), "all-mode prerequisites are joined with a comma")
	assert_true(text.begins_with("Testiperkki\nKuvaus"))


func test_locked_tooltip_joins_an_any_mode_capstone_with_or() -> void:
	var unlock := _make_unlock()
	unlock.requires_any_prerequisite = true
	var text : String = OlutoppiTextScript.locked_tooltip(unlock, PackedStringArray(["A", "B"]))
	assert_true(text.contains("A tai B"))


func test_tooltip_at_level_zero_previews_the_first_purchase_only() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 0, false)
	assert_false(text.contains("Nyt:"), "nothing to show as current yet")
	assert_true(text.contains("Tason 1 jälkeen:"))
	assert_true(text.contains(OlutoppiTextScript.TOOLTIP_NEXT_LEVEL_FORMAT % 25))


func test_tooltip_mid_level_shows_current_and_next() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 1, false)
	assert_true(text.contains("Nyt:"))
	assert_true(text.contains("Tason 2 jälkeen:"))


func test_tooltip_when_maxed_says_so_and_offers_no_next_level() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 3, true)
	assert_true(text.contains(OlutoppiTextScript.TOOLTIP_MAXED_TEXT))
	assert_false(text.contains("Seuraava taso"))


func test_tooltip_says_how_much_renown_is_missing() -> void:
	assert_true(OlutoppiTextScript.tooltip(_make_unlock(), 0, false, 10).contains(OlutoppiTextScript.TOOLTIP_RENOWN_SHORT_FORMAT % 15))
	assert_false(OlutoppiTextScript.tooltip(_make_unlock(), 0, false, 25).contains("puuttuu"), "affordable: nothing missing")
	assert_false(OlutoppiTextScript.tooltip(_make_unlock(), 0, false).contains("puuttuu"), "no renown given: no line")
